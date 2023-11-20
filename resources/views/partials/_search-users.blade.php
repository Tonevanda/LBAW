<form class = "products_search" action="" method="GET">
    {{ csrf_field() }}
    <label for="search">Search a user email:</label>
    <input type="text" name="search" value = "{{ request('search') }}">
    <button type="submit">Search</button>
</form>