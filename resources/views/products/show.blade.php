@extends('layouts.app') 

@section('content')

<script>
    var assetBaseUrl = "{{ asset('images/user_images') }}";
  </script>


<div class = 'product-page'>
    <div class="product-info">
    <div class = "product_img">
    <img src="{{ asset('images/product_images/' . $product->image) }}">
    </div>
    <div class="product-details">
    <h2> {{ $product->name }} </h2>
    <form class = "update_product" method="post" action="{{route('product.update',['product_id' => $product->id])}}">
        {{ csrf_field() }}
        <b>Author: </b><p id="author" class="editable">{{ $product->author }} </p>
        <b>Editor: </b><p id="editor" class="editable">{{ $product->editor }} </p>
        <p id="synopsis" class="synopsis editable"> {{ $product->synopsis }} </p>
        <b>Language: </b><p id="language" class="editable">{{ $product->language }} </p>
        <b>Price: </b><p id="price" class="editable">{{ $product->price }} </p>
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
                <button id="heartButton" class="heart-button" type="submit" name="add-to-wishlist">
                        <i class="fas fa-heart"></i>
                </button>
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
        @if (!Auth::user()->isAdmin())
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
                    <label for="title">Title</label>
                    <input id="title" type="text" name="title" required>
                    @if ($errors->has('title'))
                        <span class="error">
                            {{ $errors->first('title') }}
                        </span>
                    @endif
                    <label for="description">Description</label>
                    <textarea id="description" type="text" name="description" required> </textarea>
                    @if ($errors->has('description'))
                        <span class="error">
                            {{ $errors->first('description') }}
                        </span>
                    @endif
                    <label for="rating">Rating</label>
                    <input id="rating" type="number" name="rating" min="1" max="5" required>
                    @if ($errors->has('rating'))
                        <span class="error">
                            {{ $errors->first('rating') }}
                        </span>
                    @endif
                    <div class="navigation-buttons">
                        <button type="button" class="close-pop-form">Cancel</button>
                    <button type="submit" name="add-review">
                        Add Review
                    </button>
                </div>
                </form>
            </div>
            @else
                <li class="my-review" data-id="{{$userReview->id}}">
                    <div class="user-details-container">
                        <div class = "user-image">
                            <img src ="{{asset('images/user_images/' . $user->profile_picture)}}" alt="" />
                        </div>
                        <p class = "user_name"> {{$user->name}} </p>
                        <p>{{ \Carbon\Carbon::parse($userReview->date)->format('Y-m-d')}}</p>
                        <p class="edit-review"><i class="fas fa-edit"></i> Edit Review</p>
                    </div>
                    <form class = "edit_review" method="" action="">
                        {{ csrf_field() }}
                        <input type="hidden" name="review_id" value="{{ $userReview->id }}" required>
                        <label>Title</label>
                        <textarea type="text" name="title" required readonly>{{ $userReview->title }}</textarea>
                        <label>Description</label>
                        <textarea type="text" name="description" required readonly>{{ $userReview->description }}</textarea>
                        {{ $userReview->rating }}
                        <button type="submit" name="update-review">
                            Save
                        </button>
                    </form>
                    <form class = "delete_review" method="" action="{{ route('review.destroy', ['review_id' => $userReview->id]) }}">
                        {{ csrf_field() }}
                        <input type="hidden" name="product_id" value="{{ $product->id }}" required>
                        <input type="hidden" name="review_id" value="{{ $userReview->id }}" required>
                        <button type="submit" name="delete-review" class="delete-review">
                            <i class="fas fa-trash-alt"></i> Delete Review
                        </button>
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
                        <strong>
                            {{--add pfp later--}}
                            {{ \Carbon\Carbon::parse($review->date)->format('Y-m-d')}}
                            {{ $user->name}}
                            {{ $review->title}}
                        </strong>
                        <div class = "user_image">
                            <img src ="{{asset('images/user_images/' . $user->profile_picture)}}" alt="" />
                        </div>
                        <p class = "user_name"> {{$user->name}} </p>
                        <label>Title</label>
                        <textarea type="text" name="title" required readonly>{{ $review->title }}</textarea>
                        <label>Description</label>
                        <textarea type="text" name="description" required readonly>{{ $review->description }}</textarea>
                        {{ $review->rating }}
                        @if(auth()->check())
                            @if(Auth::user()->isAdmin())
                                <form class = "delete_review" method="" action="{{ route('review.destroy', ['review_id' => $review->id]) }}">
                                    {{ csrf_field() }}
                                    <input type="hidden" name="product_id" value="{{ $product->id }}" required>
                                    <input type="hidden" name="review_id" value="{{ $review->id }}" required>
                                    <button type="submit" name="delete-review" class="button button-outline">
                                        Delete Review
                                    </button>
                                </form>
                            @else
                                <form class="report_review" method="" action="{{ route('review.report', ['review_id' => $review->id]) }}">
                                    {{ csrf_field() }}
                                    <input type="hidden" name="product_id" value="{{ $product->id }}" required>
                                    <input type="hidden" name="review_id" value="{{ $review->id }}" required>
                                    <button type="submit" name="report-review" class="button button-outline">
                                        Report
                                    </button>
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