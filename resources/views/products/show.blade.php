@extends('layouts.app') 

@section('content')

<script>
    var assetBaseUrl = "{{ asset('images/product_images') }}";
</script>

@php 
    $user = Auth::user();
    if($user != null && !$user->isAdmin()){
        $wallet = $user->authenticated()->first()->wallet()->first();
        $currency = $wallet->currency()->first();
        $currency_symbol = $currency->currency_symbol;
    }
    else{
        $currency_symbol = '€';
    }
@endphp

<div class = 'product-page'>
    <div class="product-info">

        <form id = "modify_image" class="product_pic" method="" action="" enctype="multipart/form-data">
            {{ csrf_field() }}
            @method('PUT')
            <fieldset>
              <legend class="sr-only">Product Picture</legend>
              <div class = "product_image">
                <img data-info = "{{$product->image}}" src="{{ asset('images/product_images/' . $product->image) }}" alt = "" />
                <i class="fas fa-edit"></i>
              </div>
          
              <input type="file" name="product_picture" hidden>
      
                <input type="submit" name="update_pic" value="{{ true }}" hidden>
            </fieldset>
          </form>
        
        <div class="product-details">
        <h2> {{ $product->name }} </h2>
        <form class = "update_product" method="post" action="{{route('product.update',['product_id' => $product->id])}}">
            {{ csrf_field() }}
            <fieldset>
                <input type = "text" name = "image" value = "{{$product->image}}" hidden/>
              </fieldset>
            <fieldset>
                <legend class="sr-only">Author</legend>
                <b>Author: </b><p id="author" class="editable">{{ $product->author }} </p>
            </fieldset>
            <fieldset>
                <legend class="sr-only">Editor</legend>
                <b>Editor: </b><p id="editor" class="editable">{{ $product->editor }} </p>
            </fieldset>
            <fieldset>
                <legend class="sr-only">Synopsis</legend>
                <p id="synopsis" class="synopsis editable"> {{ $product->synopsis }} </p>
            </fieldset>
            <fieldset>
                <legend class="sr-only">Language</legend>
                <b>Language: </b><p id="language" class="editable">{{ $product->language }} </p>
            </fieldset>
            <fieldset>
                <legend class="sr-only">Price</legend>
                <b>Price: </b><p id="price" class="editable">{{ number_format(($product->price-($product->discount*$product->price/100))/100, 2, ',', '.')}}{{$currency_symbol}} </p>
            </fieldset>
            <fieldset>
                <legend class="sr-only">Category</legend>
                <b>Category: </b><p id="category" class="editable">{{$product_category}}</p>
                <div class = "hidden_categories">
                    @foreach ($categories as $category)
                        <option name = "{{$category->category_type}}" {{$category->category_type == $product_category ? 'selected' : ''}}>{{$category->category_type}}</option>
                    @endforeach
                </div>
            </fieldset>
            <fieldset>
                <legend class="sr-only">Stock</legend>
                <b>Stock: </b><p id="stock" class="editable">{{$product->stock}}</p>
            </fieldset>
        @if (auth()->check())
            @if (!Auth::user()->isAdmin())
            </form>
            <div class="button-container">
                <form class = "add_cart" method="" action="{{ route('shopping-cart.store', ['user_id' => Auth::user()->id]) }}" enctype="multipart/form-data">
                    {{ csrf_field() }}
                    <input type="hidden" name="product_id" value="{{ $product->id }}" required>
                    <input type="hidden" name="user_id" value="{{ Auth::user()->id }}" required>
                    <button type="submit" name="add-to-cart" class = "add_cart_button" onclick="showPopup()">Add to Cart</button>
                    <div id="popup">
                        <p>Product added to cart!</p>
                    </div>
                    <div id="overlay"></div>
                </form>
                <form class = "add_wishlist" method="" action="{{ route('wishlist.store', ['user_id' => Auth::user()->id]) }}">
                    {{ csrf_field() }}
                    <input type="hidden" name="product_id" value="{{ $product->id }}" required>
                    <input type="hidden" name="user_id" value="{{ Auth::user()->id }}" required>
                    <i class="fas fa-heart" title="Add to wishlist"></i>
                </form>
            </div>
            @else
                <ul>
                    @foreach ($statistics as $statistic)
                        <li>
                            <b>{{ $statistic->statistic_type }}</b>
                            {{ $statistic->stat }}
                        </li>
                    @endforeach
                </ul>
                <p>Product Revenue: ${{ $productRevenue }}</p>
                <button type="button" class="edit_product">
                    Edit
                </button>
            </form>
            @endif
        @endif
        </div>
    </div>
        <!--review forms-->
        <div class = "user_review_option">
        @if (auth()->check())
            @if (!Auth::user()->isAdmin() && Auth::user()->authenticated()->first()->isblocked===false)
                @php
                    $user = Auth::user();
                    $userReview = $user->getReviewFromProduct($product->id)->first();
                    $user_info = $user->first();
                    empty($userReview) ? $flag = false : $flag = true;
                @endphp
                
                @if ($flag===false)
                <div class="user-details-container">
                    <div class = "user-image">
                        <img src ="{{asset('images/user_images/' . $user->profile_picture)}}" alt="" />
                    </div>
                    <p class = "user_name"> {{$user->name}} </p>
                </div>
                <button class="open-pop-form" name = "show_popup_review">Add Review</button>
                <div class="overlay"></div>
                <div class="pop-form">
                    <form class = "add_review" method="POST" action="{{ route('review.store', ['user_id' => $user->id]) }}">
                        {{ csrf_field() }}
                        <input type="hidden" name="product_id" value="{{ $product->id }}" required>
                        <input type="hidden" name="user_id" value="{{ Auth::user()->id }}" required>
                        <fieldset>
                            <legend class="sr-only">Title</legend>
                            <label for="title">Title</label>
                            <input id="title" type="text" name="title" required>
                        </fieldset>
                        @if ($errors->has('title'))
                            <span class="error">
                                {{ $errors->first('title') }}
                            </span>
                        @endif
                        <fieldset>
                            <legend class="sr-only">Description</legend>
                            <label for="description">Description</label>
                            <textarea id="description" type="text" name="description" required> </textarea>
                        </fieldset>
                        @if ($errors->has('description'))
                            <span class="error">
                                {{ $errors->first('description') }}
                            </span>
                        @endif
                        <fieldset>
                            <legend class="sr-only">Rating</legend>
                            <label for="rating">Rating</label>
                            <input id="rating" type="number" name="rating" min="1" max="5" required>
                        </fieldset>
                        @if ($errors->has('rating'))
                            <span class="error">
                                {{ $errors->first('rating') }}
                            </span>
                        @endif
                        <div class="navigation-buttons">
                            <button type="button" class="close-pop-form" name = "cancel_review_popup">Cancel</button>
                        <button type="submit" name="add-review">
                            Add Review
                        </button>
                    </div>
                    </form>
                    <div id="errorReview" style="display: none; color: red; font-size: small;"></div>
                </div>
                @else
                    <li class="my-review" data-id="{{$userReview->id}}">
                        <div class="user-details-container">
                            <div class = "user-image">
                                <img src ="{{asset('images/user_images/' . $user->profile_picture)}}" alt="" />
                            </div>
                            <p class = "user_name"> {{$user->name}} </p>
                            <p class="small-center">{{ \Carbon\Carbon::parse($userReview->date)->format('Y-m-d')}}</p>
                            <p class="edit-review"><i class="fas fa-edit"></i><span class="header-text"> Edit Review</span></p>
                        </div>
                        <form class = "edit_review" method="" action="">
                            {{ csrf_field() }}
                            <input type="hidden" name="review_id" value="{{ $userReview->id }}" required>
                            <fieldset>
                                <legend class="sr-only">Title</legend>
                                <label>Title</label>
                                <textarea type="text" name="title" data-info = "{{$userReview->title}}" value = "{{$userReview->title}}" required readonly>{{ $userReview->title }}</textarea>
                            </fieldset>
                            <fieldset>
                                <legend class="sr-only">Description</legend>
                                <label>Description</label>
                                <textarea type="text" name="description" data-info = "{{$userReview->description}}" value = "{{$userReview->description}}" required readonly>{{ $userReview->description }}</textarea>
                            </fieldset>
                            <fieldset>
                                <div class="star-rating">
                                    @for ($i = 1; $i <= 5; $i++)
                                    <i class="fa{{ $i <= $userReview->rating ? 's' : 'r' }} fa-star"></i>
                                    @endfor   
                                </div>
                            </fieldset>
                            <button type="submit" name="update-review">
                                Save
                            </button>
                        </form>
                        <form class = "delete_review" method="" action="">
                            {{ csrf_field() }}
                            <input type="hidden" name="product_id" value="{{ $product->id }}" required>
                            <input type="hidden" name="review_id" value="{{ $userReview->id }}" required>
                            <button type="submit" name="delete-review" class="delete-review">
                                <i class="fas fa-trash-alt"></i> Delete Review
                            </button>
                            <div data-id= "{{$userReview->id}}" style="display: none; color: red; font-size: small;"></div>
                        </form>
                    </li>
                @endif
            @endif
        @endif
                </div>
        <div class="reviews">
            <ul class="list-group">
                @foreach ($reviews as $review)
                    @php
                        #dd($review);

                        $user = $review->getAuthor()->first();  
                    @endphp
                    @if(!auth()->check() || Auth::user()->id!==$user->id)
                        <li class="list-group-item" data-id="{{$review->id}}">
                            <div class="user-details-container">
                                <div class = "user-image">
                                    <img src ="{{asset('images/user_images/' . $user->profile_picture)}}" alt="" />
                                </div>
                                <p class = "user_name"> {{$user->name}} </p>
                                <p class="small-center">{{ \Carbon\Carbon::parse($review->date)->format('Y-m-d')}}</p>
                                </div>
                                <div class="star-rating">
                                    @for ($i = 1; $i <= 5; $i++)
                                    <i class="fa{{ $i <= $review->rating ? 's' : 'r' }} fa-star"></i>
                                  @endfor   
                                    </div>
                            <fieldset>
                                <legend class="sr-only">Title</legend>
                                <label>Title</label>
                                <textarea type="text" name="title" required readonly>{{ $review->title }}</textarea>
                            </fieldset>
                            <fieldset>
                                <legend class="sr-only">Description</legend>
                                <label>Description</label>
                                <textarea type="text" name="description" required readonly>{{ $review->description }}</textarea>
                            </fieldset>
                            @if(auth()->check())
                                @if(Auth::user()->isAdmin())
                                    <form class = "delete_review" method="" action="{{ route('review.destroy', ['review_id' => $review->id]) }}">
                                        {{ csrf_field() }}
                                        <input type="hidden" name="product_id" value="{{ $product->id }}" required>
                                        <input type="hidden" name="review_id" value="{{ $review->id }}" required>
                                        <button type="submit" name="delete-review" class="button button-outline">
                                            Delete Review
                                        </button>
                                        <div id="errorDeleteReview" style="display: none; color: red; font-size: small;"></div>
                                    </form>
                                @else
                                    <form class="report_review" method="" action="{{ route('review.report', ['review_id' => $review->id]) }}">
                                        {{ csrf_field() }}
                                        <input type="hidden" name="product_id" value="{{ $product->id }}" required>
                                        <input type="hidden" name="review_id" value="{{ $review->id }}" required>
                                        <button type="submit" name="report-review" class="report-review">
                                            Report
                                        </button>
                                        <div id="errorReport" style="display: none; color: red; font-size: small;"></div>
                                    </form>
                                @endif
                            @endif
                        </li>
                    @endif
                @endforeach
            </ul>
        </div>
    </div>
    @endsection
