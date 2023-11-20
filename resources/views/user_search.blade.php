@extends('layouts.app')

@section('content')

@include('partials._search-users')

<div class="user-container">
    @foreach($users as $user)
        <div class="user-box">
            <x-user-card :user="$user" />
        </div>
    @endforeach
</div>

@endsection