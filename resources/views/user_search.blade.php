@extends('layouts.app')

@section('content')
<div class="user-container">
<div class="users-sidebar">
@include('partials._search-users')
</div>
<div class="users-grid">
    @foreach($users as $user)
            <x-user-card :user="$user" />
    @endforeach
</div>
</div>
<div>
    <ul class="pagination">
        {{ $users->links() }}
    </ul>
</div>
@endsection