@props(['user'])


<div class="user">
    <a href="{{ route('profile', $user->id) }}">
        <h2> {{ $user->name }} </h2>
        <img src ="{{asset('images/user_images/' . $user->profile_picture)}}" alt="{{$user->name}}'s profile picture" />
    </a>
    
    <form method="" action="" class="form-toggle-block">
        {{ csrf_field() }}
        <button type="submit" data-id="{{$user->id}}">
            @if($user->isblocked)
                Unblock
            @else
                Block
            @endif
        </button>
    </form>
</div>
