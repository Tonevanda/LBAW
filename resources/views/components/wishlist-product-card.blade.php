@props(['product', 'user'])
<div data-id="{{$product->id}}">
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
    @if (auth()->check() && !Auth::user()->isAdmin())
    <form class = "remove_wishlist" method="" action="{{ route('wishlist.destroy', ['user_id' => $user->user_id]) }}">
        <fieldset>
            <legend class="sr-only">Remove from Wishlist</legend>
            {{ csrf_field() }}
            <input type="hidden" name="product_id" value="{{ $product->id }}" required>
            <input type="hidden" name="user_id" value="{{ Auth::user()->id }}" required>
            <button type="submit" name="remove-from-wishlist" class="cancel">
                Remove
            </button>
        </fieldset>
    </form>
    @endif
</div>
</div>
