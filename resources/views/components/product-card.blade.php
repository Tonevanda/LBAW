@props(['product', 'currency_symbol'])


<div class="product" id="product-{{ $product->id }}">
    <a href="{{ route('single-product', $product->id) }}">
    <div class = "product_image" title="Read more about this">
        <img src= "{{asset('images/product_images/' . $product->image)}}" alt="" />
    </div>
    <h2> {{ $product->name }} </h2>
        <p> {{ number_format(($product->price-($product->discount*$product->price/100))/100, 2, ',', '.')}}{{$currency_symbol}} </p>
        <p> {{ $product->discount }} </p>
    @if ($product->stock > 0 && $product->stock < 10)
        <p class="low-stock">Only {{$product->stock}} left in stock</p>
    @elseif ($product->stock === 0)
        <p class="low-stock">Out of stock</p>
    @endif
    </a>
    @if (auth()->check())
        @if (!Auth::user()->isAdmin())
            <div class="button-container">
                <form class = "add_cart" method="" action="{{ route('shopping-cart.store', ['user_id' => Auth::user()->id]) }}" enctype="multipart/form-data">
                    {{ csrf_field() }}
                    <input type="hidden" name="product_id" value="{{ $product->id }}" required>
                    <input type="hidden" name="user_id" value="{{ Auth::user()->id }}" required>
                    <button type="submit" name="add-to-cart" class = "add_cart_button" onclick="showPopup()">Add to Cart</button>
                    <div id="popup">
                        <p>Product added to cart!</p>
                    </div>
                    <div id="overlay"></div>
                </form>
                <form class = "add_wishlist" method="" action="{{ route('wishlist.store', ['user_id' => Auth::user()->id]) }}">
                    {{ csrf_field() }}
                    <input type="hidden" name="product_id" value="{{ $product->id }}" required>
                    <input type="hidden" name="user_id" value="{{ Auth::user()->id }}" required>
                    @if(Auth::user()->authenticated()->get()->first()->wishlist->contains($product))
                        <input type="hidden" name="wishlist_id" value="{{ Auth::user()->authenticated()->get()->first()->wishlist->where('id', $product->id)->first()->pivot->id }}" required>
                    @endif
                    <button id="heartButton" class="heart-button" type="submit" name="add-to-wishlist" title="Add to wishlist">
                        <i class="fas fa-heart"></i>
                    </button>                                       
                </form>
            </div>
            <div id="errorMessage" style="display: none; color: red; font-size: small;"></div>
            <div id="errorDeleteWishlist" style="display: none; color: red; font-size: small;"></div>
        @else
        <i class="fas fa-box-open icon-box-open" title="Stock" onclick="togglePopup()"></i>

<!-- Pop-up content -->
<div class="popup" id="stockPopup">
    <p><b>In stock: </b>{{ $product->stock }}</p>
    <button class="cancel" onclick="togglePopup()">Close</button>
</div>
        @endif
    @endif
</div>