@php
use Carbon\Carbon;
@endphp
@extends('layouts.app')


@section('content')
    <div class="purchases-container">
        @foreach ($purchases as $purchase)
            <div class="purchase">
            
                <div class="product-grid">
                    @foreach($purchase->products()->get() as $product)
                        <x-history-product-card :product="$product" />
                    @endforeach
                </div>
                <p>Total Price: {{ $purchase->price }}</p>
                <a href="#">
                    <p>{{ Carbon::parse($purchase->orderedat)->format('d/m/Y H:i:s') }}</p>
                </a>
            </div>
        @endforeach
    </div>
@endsection
