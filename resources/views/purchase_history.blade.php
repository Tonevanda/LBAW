@php
use Carbon\Carbon;
@endphp
@extends('layouts.app')


@section('content')

@php
$user = Auth::user();

@endphp

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
                @if (!$user->isAdmin() && $purchase->stage_state != 'delivered' && $purchase->isRefunded == false)
                    <form method = "" action = "">
                        {{ csrf_field() }}
                        <input name = "user_id" value = {{$user->id}} hidden>
                        <button name = "cancel_order_button"> Cancel Order </button>
                    </form>
                @elseif (!$user->isAdmin() && $purchase->isRefunded == false)
                    <form method = "" action = "">
                        {{ csrf_field() }}
                        <input name = "user_id" value = {{$user->id}} hidden>
                        <button name = "refund_order_button"> Refund Order </button>
                    </form> 
                @endif
            </div>
        @endforeach
    </div>
@endsection
