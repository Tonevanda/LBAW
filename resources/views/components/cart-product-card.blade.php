@props(['product'])
<div data-id="{{$product->pivot->id}}">
    <a href="{{ route('single-product', $product) }}">
        <div class="product-info">
            <div class = "product_img">
            <img src= "{{asset('images/product_images/' . $product->image)}}" alt="" />
        </div>
        <div class="product-details">
        <h3> {{ $product->name }} </h3>
        <p> {{ $product->synopsis }} </p>
        <p> {{ $product->price }} </p>
    </a>
    @if (auth()->check())
    <form class = "remove_cart" method="" action="{{ route('shopping-cart.destroy', ['user_id' => Auth::user()->id]) }}">
        {{ csrf_field() }}
        <input type="hidden" name="cart_id" value="{{ $product->pivot->id }}" required>
        <input type="hidden" name="user_id" value="{{ Auth::user()->id }}" required>
        <button class="cancel" type="submit" name="remove-from-cart">
            Remove
        </button>
    </form>
    @endif
</div>
</div>
</div>
