<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Notification extends Model
{
    use HasFactory;

    protected $table = 'notification';

    protected $fillable = ['notification_type', 'description'];

    public $timestamps = false;

    protected $primaryKey = 'notification_type';

    public function user()
    {
        return $this->belongsToMany(Authenticated::class, 'authenticated_notification', 'notification_type', 'user_id')->withPivot('id');
    }
}
