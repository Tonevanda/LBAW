@props(['product', 'user'])
<div class="product" data-id="{{$product->id}}">
    <a href="{{ route('single-product', $product) }}">
        <h2> {{ $product->name }} </h2>
        <p> {{ $product->synopsis }} </p>
        <p> {{ $product->price }} </p>
    </a>
    @if (auth()->check() && !Auth::user()->isAdmin())
    <form class = "remove_wishlist" method="" action="{{ route('wishlist.destroy', ['user_id' => $user->user_id]) }}">
        {{ csrf_field() }}
        {{ $product->pivot->id }}
        <input type="hidden" name="product_id" value="{{ $product->id }}" required>
        <input type="hidden" name="user_id" value="{{ Auth::user()->id }}" required>
        <button type="submit" name="remove-from-wishlist" class="button button-outline">
            Remove
        </button>
    </form>
    @endif
</div>
