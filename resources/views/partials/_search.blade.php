<form class = "products_search" action="" method="GET">
    {{ csrf_field() }}
    <input type="text" name="search" value = "{{ request('search') }}">
    <label for="category">Select an option:</label>
    <select name="category">
        <option value="" {{ request('category') == '' ? 'selected' : '' }}></option>
        <option value="drama" {{ request('category') == 'drama' ? 'selected' : '' }}>Drama</option>
        <option value="romance" {{ request('category') == 'romance' ? 'selected' : '' }}>Romance</option>
        <option value="horror" {{ request('category') == 'horror' ? 'selected' : '' }}>Horror</option>
    <!-- Add more options as needed -->
    </select>
    <label for="price">Select a price:</label>
    <input type="range" name="price" min="0" max="500" step="1" value= "{{ request('price') }}">
    <div>
        {{ request('price') == '' ? '250' : request('price')}}
    </div>
    <button type="submit">Search</button>
</form>