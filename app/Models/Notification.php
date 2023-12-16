<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Notification extends Model
{
    use HasFactory;

    protected $table = 'authenticated_notification';

    protected $fillable = ['user_id', 'notification_type', 'date', 'isnew'];

    public $timestamps = false;

    protected $primaryKey = 'id';

    public function user()
    {
        return $this->belongsTo(Authenticated::class, 'user_id');
    }

    public function notificationType()
    {
        return $this->belongsTo(NotificationType::class, 'notification_type');
    }
}
