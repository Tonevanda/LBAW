@props(['product', 'currency_symbol'])
<div class="product">
    <a href="{{ route('single-product', $product) }}">
        <div class = "product_image">
            <img src= "{{asset('images/product_images/' . $product->image)}}" alt="{{$product->name}} image" />
        </div>
        <h2> {{ $product->name }} </h2>
        <p> {{ number_format(($product->price-($product->price*$product->discount/100))/100, 2, ',', '.')}}{{$currency_symbol}} </p>
    </a>
</div>
