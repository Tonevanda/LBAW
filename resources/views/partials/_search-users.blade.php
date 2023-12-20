<form class="users_search" action="" method="GET">
    {{ csrf_field() }}
    <fieldset>
        <legend class="sr-only">Search User</legend>
        <label for="search">Search a user email:</label>
        <input type="text" name="search" placeholder="Enter user email" value="{{ request('search') }}">
        <button type="submit">Search</button>
    </fieldset>
</form>