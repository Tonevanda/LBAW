@extends('layouts.app')


@section('content')
<div class="notifications-page">
    <div class="notifications-container">
        @foreach ($notifications as $notification)
            <div class="notifications">
                <div class="n-title">
                <p class=circle> {{$notification->id}} </p>
                <p class="left"><b> Notification Type: {{$notification->notification_type}}</b> </p>
                <p class="right"> {{$notification->date}} </p>
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
