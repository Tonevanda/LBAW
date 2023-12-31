@props(['product', 'user'])
@php 
    $wallet = $user->wallet()->first();
    $currency = $wallet->currency()->first();
@endphp
<div data-id="{{$product->id}}">
    <div class="product-info">
        <a href="{{ route('single-product', $product) }}">
            <div class = "product_img">
                <img src= "{{asset('images/product_images/' . $product->image)}}" alt="{{$product->name}} image" />
            </div>
        </a>
        <div class="product-details">
            <h3> {{ $product->name }} </h3>
            <p> {{ $product->synopsis }} </p>
            <p> {{ number_format(($product->price-($product->discount*$product->price/100))/100, 2, ',', '.')}}{{$currency->currency_symbol}} </p>
            @if (auth()->check() && !Auth::user()->isAdmin())
            <form class = "remove_wishlist" method="POST" action="{{ route('wishlist.destroy', ['user_id' => $user->user_id]) }}">
                <fieldset>
                    <legend class="sr-only">Remove from Wishlist</legend>
                    {{ csrf_field() }}
                    <input type="hidden" name="product_id" value="{{ $product->id }}">
                    <input type="hidden" name="user_id" value="{{ Auth::user()->id }}">
                    <button type="submit" name="remove-from-wishlist" class="cancel">
                        Remove
                    </button>
                </fieldset>
            </form>
            @endif
        </div>
    </div>
</div>
