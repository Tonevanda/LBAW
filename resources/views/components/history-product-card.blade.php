@props(['product'])
<div class="product">
    <a href="{{ route('single-product', $product) }}">
        <div class = "product_image">
            <img src= "{{asset('images/product_images/' . $product->image)}}" alt="" />
        </div>
        <h2> {{ $product->name }} </h2>
        <p> {{ $product->price }} </p>
    </a>
</div>
