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
                    <p>{{$notification->pivot->notification_type}}</p>
                </b> </div>
                <p class="right">{{ Carbon::parse($notification->date)->format('d/m/Y H:i:s') }} </p>
            </div>
                <p class="padding-left"> {{$notification->description}} </p>
                @if($notification->isnew == 1)
                    <p><b>New</b></p>
                @endif
            </div>
        @endforeach
    </div>
</div>
@endsection
