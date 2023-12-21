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
                @if (!$user->isAdmin() && $purchase->stage_state != 'delivered' && $purchase->isrefunded == false)
                    <form class = "refund_cancel_purchase" method = "" action = "" data-id = "{{$purchase->id}}">
                        {{ csrf_field() }}
                        <input name = "user_id" value = {{$user->id}} hidden>
                        <button type = "submit" name = "cancel_order_button"> Cancel Order </button>
                    </form>
                @elseif (!$user->isAdmin() && $purchase->isrefunded == false)
                    <form class = "refund_cancel_purchase" method = "" action = "" data-id = "{{$purchase->id}}">
                        {{ csrf_field() }}
                        <input name = "user_id" value = {{$user->id}} hidden>
                        <button type = "submit" name = "refund_order_button"> Refund Order </button>
                    </form> 
                @endif
                <div id="errorMessage" style="display: none; color: red; font-size: small;"></div>
            </div>
        @endforeach
    </div>
@endsection
