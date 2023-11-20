@extends('layouts.app')


@section('content')

@include('partials._search-users')

@foreach($users as $user)
    
    <x-user-card :user="$user" />

@endforeach

@endsection