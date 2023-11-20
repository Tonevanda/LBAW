@php
use Carbon\Carbon;
@endphp
@extends('layouts.app')

@section('content')

@foreach ($purchases as $purchase)

<div class="purchase">

    <a href="#">
        <p> {{ Carbon::parse($purchase->orderedat)->format('d/m/Y H:i:s') }} </p>
        @foreach($purchase->products()->get() as $product)
            <x-history-product-card :product="$product" />
        @endforeach
    </a>

</div>

@endforeach

@endsection

