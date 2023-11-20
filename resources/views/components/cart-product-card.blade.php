@props(['product'])
<div class="product" data-id="{{$product->pivot->id}}">
    <a href="{{ route('single-product', $product) }}">
        <h2> {{ $product->name }} </h2>
        <p> {{ $product->synopsis }} </p>
        <p> {{ $product->price }} </p>
    </a>
    @if (auth()->check())
    <form class = "remove_cart" method="" action="{{ route('shopping-cart.destroy', ['user_id' => Auth::user()->id]) }}">
        {{ csrf_field() }}
        <input type="hidden" name="cart_id" value="{{ $product->pivot->id }}" required>
        <input type="hidden" name="user_id" value="{{ Auth::user()->id }}" required>
        <button type="submit" name="remove-from-cart" class="button button-outline">
            Remove
        </button>
    </form>
    @endif
</div>
