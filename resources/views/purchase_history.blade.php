@php
use Carbon\Carbon;
@endphp
@extends('layouts.app')


@section('content')

@php
$user = Auth::user();
$currency_symbol = '€';
if($user != null && !$user->isAdmin()){
    $auth = $user->authenticated()->first();
    $wallet = $auth->wallet()->first();
    $currency_symbol = $wallet->currency()->first()->currency_symbol; 
}



@endphp

    <div class="purchases-container">
        @foreach ($purchases as $purchase)
            <div class="purchase">
                <div class="product-grid">
                    @foreach($purchase->products()->get() as $product)
                        <x-history-product-card :product="$product" :currency_symbol="$currency_symbol"/>
                    @endforeach
                </div>
                <p>Total Price: {{ number_format($purchase->price/100, 2, ',', '.')}}{{$currency_symbol}}</p>
                <p>Payment Method: {{ $purchase->payment_type }}</p>
                <a href="#">
                    <p>{{ Carbon::parse($purchase->orderedat)->format('d/m/Y H:i:s') }} {{$purchase->destination}}</p>
                </a>
                @if (!$user->isAdmin() && $purchase->stage_state != 'delivered' && $purchase->refundedat == null)
                    <form class = "refund_cancel_purchase" method = "" action = "" data-id = "{{$purchase->id}}">
                        {{ csrf_field() }}
                        <input name = "user_id" value = {{$user->id}} hidden>
                        <button type = "submit" name = "cancel_order_button"> Cancel Order </button>
                    </form>
                @elseif (!$user->isAdmin() && $purchase->refundedat != null)
                    <form class = "refund_cancel_purchase" method = "" action = "" data-id = "{{$purchase->id}}">
                        {{ csrf_field() }}
                        <input name = "user_id" value = {{$user->id}} hidden>
                        <button type = "submit" name = "refund_order_button"> Refund Order </button>
                    </form> 
                @endif
                <div data-id = "{{$purchase->id}}" style="display: none; color: red; font-size: small;"></div>
            </div>
        @endforeach
    </div>
@endsection
