<form class = "products_search" action="" method="GET">
    {{ csrf_field() }}
    <input type="text" name="search" value = "{{ request('search') }}">
    <label for="category">Select an option:</label>
    <select name="category">
        <option value="" selected></option>
        <option value="drama">Drama</option>
        <option value="romance">Romance</option>
        <option value="horror">Horror</option>
    <!-- Add more options as needed -->
    </select>
    <label for="price">Select a price:</label>
    <input type="range" name="price" min="0" max="500" step="1" value= "{{ request('price') }}">
    <button type="submit">Search</button>
</form>