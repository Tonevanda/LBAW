@props(['user'])

<div class="user">
    <a href="{{ route('profile', $user->id) }}">
        <h3> {{ $user->name }} </h3>
        <p> {{ $user->email }} </p>
    </a>
</div>
