@extends('layouts.app')

@section('content')


<div class = 'product-page'>
  <div class="product-info">
  <div class = "product_img">
  <img src="{{ asset('images/product_images/' . 'default.png') }}">
      </div>
      <div class="product-details">
      <h2> Please Submit Name </h2>
      <form class = "update_product" method="" action="">
          {{ csrf_field() }}
          <fieldset>
              <legend class="sr-only">Author</legend>
              <b>Author: </b><p id="author" class="editable">Enter Author</p>
          </fieldset>
          <fieldset>
              <legend class="sr-only">Editor</legend>
              <b>Editor: </b><p id="editor" class="editable">Enter Editor</p>
          </fieldset>
          <fieldset>
              <legend class="sr-only">Synopsis</legend>
              <p id="synopsis" class="synopsis editable">Fill this synopsis</p>
          </fieldset>
          <fieldset>
              <legend class="sr-only">Language</legend>
              <b>Language: </b><p id="language" class="editable">English</p>
          </fieldset>
          <fieldset>
              <legend class="sr-only">Price</legend>
              <b>Price: </b><p id="price" class="editable">2,50€</p>
          </fieldset>
        <button type="button" class="edit_product">
            Edit
        </button>
      </form>
        </div>
  </div>
@endsection