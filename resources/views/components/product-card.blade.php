@props(['product'])

<div class="product">
    <a href="{{ route('single-product', $product->id) }}">
        <h2> {{ $product->name }} </h2>
        <p> {{ $product->synopsis }} </p>
        <p> {{ $product->price }} </p>
    </a>
    @if (auth()->check())
    <form class = "add_cart" method="" action="{{ route('shopping-cart.store', ['user_id' => Auth::user()->id]) }}">
        {{ csrf_field() }}
        <input type="hidden" name="product_id" value="{{ $product->id }}" required>
        <input type="hidden" name="user_id" value="{{ Auth::user()->id }}" required>
        <button type="submit" name="add-to-cart" class="button button-outline">
            Add to Cart
        </button>
    </form>
    @endif
</div>