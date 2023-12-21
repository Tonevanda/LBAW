@extends('layouts.app')

@section('content')


<div class = 'product-page'>
  <div class="product-info">
  <div class = "product_img">
  <img src="{{ asset('images/product_images/' . 'default.png') }}">
      </div>
      <div class="product-details">

      <form class = "add_product" method="POST" action="{{route('product.create')}}">
          {{ csrf_field() }}
          <fieldset>
            <legend class="sr-only">Name</legend>
            <b> Name </b>
            <textarea id = "name" placeholder="Enter the book's Name here..."></textarea>
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
              <textarea id = "synopsis" placeholder="Enter the book's Synopsis here..."></textarea>
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
              <textarea id = "price" placeholder="Enter the book's Price here..."></textarea>
              <input type = "text" name = "price" hidden>
          </fieldset>
          <fieldset>
            <legend class="sr-only">Stock</legend>
            <b>Stock: </b>
            <textarea id = "stock" placeholder="Enter the book's Stock here..."></textarea>
            <input type = "text" name = "stock" hidden>
        </fieldset>
        <button type="submit">
            Add Book
        </button>
      </form>
        </div>
  </div>
@endsection