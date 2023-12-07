@props(['product'])
<div class="product" data-id="{{$product->pivot->id}}">
    <a href="{{ route('single-product', $product) }}">
        <h2> {{ $product->name }} </h2>
        <p> {{ $product->synopsis }} </p>
        <p> {{ $product->price }} </p>
    </a>
    @if (auth()->check())
    <form class = "remove_wishlist" method="" action="{{ route('wishlist.destroy', ['user_id' => Auth::user()->id]) }}">
        {{ csrf_field() }}
        {{ $product->pivot->id }}
        <input type="hidden" name="wishlist_id" value="{{ $product->pivot->id }}" required>
        <input type="hidden" name="user_id" value="{{ Auth::user()->id }}" required>
        <button type="submit" name="remove-from-wishlist" class="button button-outline">
            Remove
        </button>
    </form>
    @endif
</div>
