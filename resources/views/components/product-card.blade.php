@props(['product'])

<div class="product">
    <a href="{{ route('single-product', $product) }}">
        <h2> {{ $product->name }} </h2>
        <p> {{ $product->synopsis }} </p>
        <p> {{ $product->price }} </p>
    </a>
    <form method="POST" action="{{ route('shopping-cart.store', ['user' => Auth::user()]) }}">
        {{ csrf_field() }}
        <input type="hidden" name="product_id" value="{{ $product->id }}">
        <button type="submit" class="button button-outline">
            Add to Cart
        </button>
    </form>
</div>