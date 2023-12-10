@props(['product'])

<div class="product">
    <a href="{{ route('single-product', $product->id) }}">
    <div class = "product_image">
        <img src= "{{asset('images/product_images/' . $product->image)}}" alt="" />
    </div>
    <h2> {{ $product->name }} </h2>
        <p> {{ $product->price }} </p>
    </a>
    @if (auth()->check())
        @if (!Auth::user()->isAdmin())
            <form class = "add_cart" method="" action="{{ route('shopping-cart.store', ['user_id' => Auth::user()->id]) }}" enctype="multipart/form-data">
                {{ csrf_field() }}
                <input type="hidden" name="product_id" value="{{ $product->id }}" required>
                <input type="hidden" name="user_id" value="{{ Auth::user()->id }}" required>
                <button type="submit" name="add-to-cart" class="button button-outline" onclick="showPopup()">Add to Cart</button>
                <div id="popup">
                    <p>Product added to cart!</p>
                    <!-- No need for a close button if it disappears automatically -->
                </div>
                <div id="overlay"></div>
            </form>
            <form class = "add_wishlist" method="" action="{{ route('wishlist.store', ['user_id' => Auth::user()->id]) }}">
                {{ csrf_field() }}
                <input type="hidden" name="product_id" value="{{ $product->id }}" required>
                <input type="hidden" name="user_id" value="{{ Auth::user()->id }}" required>
                <button type="submit" name="add-to-wishlist" class="button button-outline">
                    Add to Wishlist
                </button>
            </form>
        @endif
    @endif
</div>