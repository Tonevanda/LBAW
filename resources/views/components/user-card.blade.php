@props(['user'])

<div class="user">
    <a href="{{ route('profile', $user->id) }}">
        <h2> {{ $user->name }} </h2>
        <p> {{ $user->email }} </p>
    </a>
</div>
