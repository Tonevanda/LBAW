@props(['product', 'user'])
@php 
    if(!$user->isAdmin()){
        $auth = $user->authenticated()->first();
        $wallet = $auth->wallet()->first();
        $currency = $wallet->currency()->first();
    }
@endphp
<div data-id="{{$product->pivot->id}}">
    <a href="{{ route('single-product', $product) }}">
        <div class="product-info">
            <div class = "product_img">
            <img src= "{{asset('images/product_images/' . $product->image)}}" alt="{{$product->name}} image" />
        </div>
        <div class="product-details">
        <h3> {{ $product->name }} </h3>
        <p> {{ $product->synopsis }} </p>
        <p> {{ number_format(($product->price-($product->discount*$product->price/100))/100, 2, ',', '.')}}{{$user->isAdmin() ? '€' : $currency->currency_symbol}} </p>
    </a>
    @if (auth()->check())
    <form class="remove_cart" method="" action="{{ route('shopping-cart.destroy', ['user_id' => Auth::user()->id]) }}">
        {{ csrf_field() }}
        <fieldset>
            <legend class="sr-only">Remove from Cart</legend>
            <input type="hidden" name="cart_id" value="{{ $product->pivot->id }}" required>
            <input type="hidden" name="user_id" value="{{ Auth::user()->id }}" required>
            <button class="cancel" type="submit" name="remove-from-cart">
                Remove
            </button>
        </fieldset>
    </form>
    <div class = "error_message" style="display: none; color: red; font-size: small;"></div>
    @endif
</div>
</div>
</div>
