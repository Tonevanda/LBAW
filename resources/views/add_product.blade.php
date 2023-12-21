@extends('layouts.app')

@section('content')


<script>
  var assetBaseUrl = "{{ asset('images/product_images') }}";
</script>

<div class = 'product-page'>
  <div class="product-info">
    <form class="product_pic" method="" action="" enctype="multipart/form-data">
      {{ csrf_field() }}
      @method('PUT')
      <fieldset>
        <legend class="sr-only">Profile Picture</legend>
        <div class = "product_image">
          <img src="{{ asset('images/product_images/' . 'default.png') }}" alt = "" />
          <i class="fas fa-edit"></i>
        </div>
    
        <input type="file" name="product_picture" hidden>

          <input type="submit" name="update_pic" value="{{ false }}" hidden>
      </fieldset>
    </form>
      <div class="product-details">

      <form class = "add_product" method="POST" action="{{route('product.create')}}">
          {{ csrf_field() }}
          <fieldset>
            <input type = "text" name = "image_name" value = "default.png" hidden/>
          </fieldset>
          <fieldset>
            <legend class="sr-only">Name</legend>
            <b> Name </b>
            <textarea id = "name" placeholder="Enter the book's Name here..." required></textarea>
            <input type = "text" name = "name" hidden>
        </fieldset>
          <fieldset>
              <legend class="sr-only">Author</legend>
              <b>Author: </b>
              <textarea id = "author" placeholder="Enter the book's Author here..."></textarea>
              <input type = "text" name = "author" hidden>
          </fieldset>
          <fieldset>
              <legend class="sr-only">Editor</legend>
              <b>Editor: </b>
              <textarea id = "editor" placeholder="Enter the book's Editor here..."></textarea>
              <input type = "text" name = "editor" hidden>
          </fieldset>
          <fieldset>
              <legend class="sr-only">Synopsis</legend>
              <b>Synopsis: </b>
              <textarea id = "synopsis" placeholder="Enter the book's Synopsis here..." required></textarea>
              <input type = "text" name = "synopsis" hidden>
          </fieldset>
          <fieldset>
              <legend class="sr-only">Language</legend>
              <b>Language: </b>
              <textarea id = "language" placeholder="Enter the book's language here..."></textarea>
              <input type = "text" name = "language" hidden>
          </fieldset>
          <fieldset>
              <legend class="sr-only">Price</legend>
              <b>Price: </b>
              <textarea id = "price" placeholder="Enter the book's Price here..." required></textarea>
              <input type = "text" name = "price" hidden>
          </fieldset>
          <fieldset>
            <legend class="sr-only">Stock</legend>
            <b>Stock: </b>
            <textarea id = "stock" placeholder="Enter the book's Stock here..." required></textarea>
            <input type = "text" name = "stock" hidden>
        </fieldset>
        <fieldset>
          <legend class="sr-only">Category</legend>
          <b>Category: </b>
          <select id = "category" name = "category">
            <option value = "" selected></option>
            @foreach ($categories as $category)
              <option value = "{{$category->category_type}}">{{$category->category_type}}</option>
            @endforeach
          </select>
      </fieldset>
        <button type="submit">
            Add Book
        </button>
      </form>
        </div>
  </div>
@endsection