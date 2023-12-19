@php
use Carbon\Carbon;
@endphp
@extends('layouts.app')

@section('content')
<div class="notifications-page">
    <div class="notifications-container">
        @foreach ($notifications as $notification)
            <div class="notifications">
                <div class="n-title">
                <p class=circle> {{$notification->id}} </p>
                <div class="left"><b> 
                    @if ($notification->notification_type == 'payment_notification')
                        <p>Payment Notification</p>
                    @elseif ($notification->notification_type == 'instock_notification')
                        <p>In Stock Notification</p>
                    @elseif ($notification->notification_type == 'purchaseinfo_notification')
                         <p>Purchase Information Notification</p>
                    @elseif ($notification->notification_type == 'pricechange_notification')
                        <p>Price Change Notification</p>
                @endif
                </b> </div>
                <p class="right">{{ Carbon::parse($notification->date)->format('d/m/Y H:i:s') }} </p>
            </div>
                <p class="padding-left"> {{$notification->notificationType()->get()->first()->description}} </p>
                @if($notification->isnew == 1)
                    <p><b>New</b></p>
                @endif
            </div>
        @endforeach
    </div>
</div>
@endsection
