@extends('layouts.app') 

@section('content')

    <h2> {{ $product->name }} </h2>
    <img src="{{ asset('images/product_images/' . $product->image) }}">
    <p> {{ $product->synopsis }} </p>
    <p> {{ $product->price }} </p>
    @if (auth()->check())
        @if (!Auth::user()->isAdmin())
            <form class = "add_cart" method="" action="{{ route('shopping-cart.store', ['user_id' => Auth::user()->id]) }}">
                {{ csrf_field() }}
                <input type="hidden" name="product_id" value="{{ $product->id }}" required>
                <input type="hidden" name="user_id" value="{{ Auth::user()->id }}" required>
                <button type="submit" name="add-to-cart" class="button button-outline">
                    Add to Cart
                </button>
            </form>
            @else
            <ul>
                @foreach ($statistics as $statistic)
                    <li>
                        {{ $statistic->statistic_type }}
                    </li>
                @endforeach
            </ul>
            <p>Product Revenue: ${{ $productRevenue }}</p>
        @endif
    @endif
    <!--review forms-->
    @if (auth()->check())
        @if (!Auth::user()->isAdmin())
            @php
                $userReview = Auth::user()->authenticated()->get()[0]->getReviewFromProduct($product->id);
                empty($userReview) ? $flag = false : $flag = true;
            @endphp
            @if ($flag===false)
                <form class = "add_review" method="POST" action="{{ route('review.store', ['user_id' => Auth::user()->id]) }}">
                    {{ csrf_field() }}
                    <input type="hidden" name="product_id" value="{{ $product->id }}" required>
                    <label for="title">Title</label>
                    <input id="title" type="text" name="title" required>
                    @if ($errors->has('title'))
                        <span class="error">
                            {{ $errors->first('title') }}
                        </span>
                    @endif
                    <label for="description">Description</label>
                    <input id="description" type="text" name="description" required>
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
                    <button type="submit" name="add-review" class="button button-outline">
                        Add Review
                    </button>
                </form>
            @else
                <li class="my-review" data-id="{{$userReview->id}}">
                    <form class = "edit_review" method="" action="">
                        {{ csrf_field() }}
                        <input type="hidden" name="review_id" value="{{ $userReview->id }}" required>
                        <strong>
                            {{--add pfp later--}}
                            {{ \Carbon\Carbon::parse($userReview->date)->format('Y-m-d')}}
                            {{ $userReview->getAuthor()->get()[0]->user()->get()[0]->name}}
                            {{ $userReview->title}}
                        </strong>
                        <textarea type="text" name="description" required readonly>{{ $userReview->description }}</textarea>
                        {{ $userReview->rating }}
                        <button type="submit" name="update-review">
                            Save
                        </button>
                        <i class="fas fa-edit"></i>
                    </form>
                    <form class = "delete_review" method="" action="{{ route('review.destroy', ['review_id' => $userReview->id]) }}">
                        {{ csrf_field() }}
                        <input type="hidden" name="product_id" value="{{ $product->id }}" required>
                        <input type="hidden" name="review_id" value="{{ $userReview->id }}" required>
                        <button type="submit" name="delete-review" class="button button-outline">
                            Delete Review
                        </button>
                    </form>
                </li>
            @endif
        @endif
    @endif
    <div class="reviews">
        <ul class="list-group">
            @foreach ($reviews as $review)
                @php
                    #dd($review);
                    $user = $review->getAuthor()->get()[0]->user()->get()[0];    
                @endphp
                @if(!auth()->check() || Auth::user()->id!==$user->id)
                    <li class="list-group-item" data-id="{{$review->id}}">
                        <strong>
                            {{--add pfp later--}}
                            {{ \Carbon\Carbon::parse($review->date)->format('Y-m-d')}}
                            {{ $user->name}}
                            {{ $review->title}}
                        </strong>
                        {{ $review->description }}
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
@endsection