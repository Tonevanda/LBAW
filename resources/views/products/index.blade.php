@extends('layouts.app')

@section('content')
@php 
    $user = Auth::user();
    if($user != null && !$user->isAdmin()){
        $wallet = $user->authenticated()->first()->wallet()->first();
        $currency = $wallet->currency()->first();
        $currency_symbol = $currency->currency_symbol;
    }
    else{
        $currency_symbol = '€';
    }
    
@endphp
<div class="home-container">
@include('partials._search-products')

<div class = "home-grid">
@foreach ($products as $product)

<x-product-card :product="$product" :currency_symbol="$currency_symbol" />

@endforeach
</div>
</div>
<div>
<ul class="pagination">
    {{ $products->links() }}
</ul>
</div>
@endsection