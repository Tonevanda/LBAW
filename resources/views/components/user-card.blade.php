@props(['user'])

<div class="user">
    <a href="{{ route('profile', $user->id) }}">
        <h2> {{ $user->name }} </h2>
        <img src ="{{asset('images/user_images/' . $user->profile_picture)}}" alt="" />
    </a>
</div>
