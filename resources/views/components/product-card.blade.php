@props(['product'])

<div class="product">
    <a href="{{ route('single-product', $product) }}">
        <h2> {{ $product->name }} </h2>
        <p> {{ $product->synopsis }} </p>
        <p> {{ $product->price }} </p>
    </a>
    @if (auth()->check())
    <form method="POST" action="{{ route('shopping-cart.store', ['user' => Auth::user()]) }}">
        {{ csrf_field() }}
        <input type="hidden" name="product_id" value="{{ $product->id }}">
        <input type="hidden" name="user-id" value="{{ Auth::user() }}">
        <button type="submit" name="add-to-cart" class="button button-outline">
            Add to Cart
        </button>
    </form>
    @endif
</div>