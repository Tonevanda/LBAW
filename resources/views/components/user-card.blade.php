@props(['user'])


<div class="user">
    <a href="{{ route('profile', $user->id) }}">
        <h5><b> {{ $user->name }} </b></h5>
        <img src ="{{asset('images/user_images/' . $user->profile_picture)}}" alt="{{$user->name}}'s profile picture" />
    </a>
    
    <form method="" action="" class="form-toggle-block">
        {{ csrf_field() }}
        <button class="block" type="submit" data-id="{{$user->id}}">
            @if($user->isblocked)
                Unblock
            @else
                Block
            @endif
        </button>
    </form>
    <form method="" action="" class="delete_user" id="delete_user_form">
        {{ csrf_field() }}
        <button class="delete" type="submit" data-id="{{$user->id}}">
            Delete
        </button>
    </form>
    <form action="{{route('purchase_history',$user->id)}}">
        {{ csrf_field() }}
        <button class="purchase_history" type="submit" data-id="{{$user->id}}">
            View Purchase History
        </button>
    </form>
</div>
