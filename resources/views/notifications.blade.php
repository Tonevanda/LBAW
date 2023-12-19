@extends('layouts.app')


@section('content')
    <div class="notifications-container">
        @foreach ($notifications as $notification)
            <div class="notifications">
                <p> {{$notification->id}} </p>
                <p> {{$notification->notification_type}} </p>
                <p> {{$notification->notificationType()->get()->first()->description}} </p>
                <p> {{$notification->date}} </p>
                <p> {{$notification->isnew}} </p>
            </div>
        @endforeach
    </div>
@endsection
