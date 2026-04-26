"""
Beauty Shelf - Push notification service
"""
import platform
import threading
import time
from datetime import date, timedelta
from dataclasses import dataclass, field
from typing import Optional

from database import get_all_products, get_setting, set_setting


@dataclass
class NotificationConfig:
    """Notification settings."""
    enabled: bool = True
    days_before: int = 7  # Notify this many days before expiry


class NotificationService:
    """
    Service for checking expiring products and sending notifications.
    
    For cross-platform support:
    - Desktop: Uses system notifications via plyer or Flet's native support
    - Mobile: Uses Flet's notification API
    - For real push notifications (cross-device), integrate Firebase Cloud Messaging
    """
    
    def __init__(self, config: NotificationConfig = None):
        self.config = config or self._load_config()
    
    def _load_config(self) -> NotificationConfig:
        """Load notification settings from database."""
        enabled_str = get_setting("notifications_enabled")
        days_str = get_setting("notification_days")
        
        return NotificationConfig(
            enabled=enabled_str != "false",  # Default True
            days_before=int(days_str) if days_str else 7,
        )
    
    def save_config(self):
        """Save current config to database."""
        set_setting("notifications_enabled", str(self.config.enabled).lower())
        set_setting("notification_days", str(self.config.days_before))
    
    def get_expiring_products(self, days: int = None) -> list[dict]:
        """Get products expiring within the specified days."""
        days = days if days is not None else self.config.days_before
        threshold = date.today() + timedelta(days=days)
        
        products = get_all_products()
        expiring = []
        
        for p in products:
            expiry = date.fromisoformat(p["expiry_date"])
            if expiry <= threshold and expiry >= date.today():
                days_left = (expiry - date.today()).days
                p["days_left"] = days_left
                expiring.append(p)
        
        return sorted(expiring, key=lambda x: x["days_left"])
    
    def get_expired_products(self) -> list[dict]:
        """Get already expired products."""
        today = date.today()
        products = get_all_products()
        
        expired = []
        for p in products:
            expiry = date.fromisoformat(p["expiry_date"])
            if expiry < today:
                p["days_expired"] = (today - expiry).days
                expired.append(p)
        
        return sorted(expired, key=lambda x: -x["days_expired"])
    
    def check_and_notify(self, notify_callback=None):
        """
        Check for expiring products and send notifications.
        
        Args:
            notify_callback: Function to call with notification message.
                           If None, uses system notification.
        """
        if not self.config.enabled:
            return
        
        # Get products expiring soon
        expiring = self.get_expiring_products()
        
        if not expiring:
            return
        
        # Group by urgency
        urgent = [p for p in expiring if p["days_left"] <= 3]
        soon = [p for p in expiring if 3 < p["days_left"] <= 7]
        
        # Send notifications
        if urgent:
            names = ", ".join([p["name"] for p in urgent[:3]])
            if len(urgent) > 3:
                names += f" и ещё {len(urgent) - 3}"
            message = f"⚠️ Скоро истекает: {names}"
            self._send_notification(message, urgent, notify_callback)
        
        if soon and not urgent:
            # Only notify once per day for "soon" products
            last_notified = get_setting("last_notification_date")
            today = str(date.today())
            
            if last_notified != today:
                names = ", ".join([p["name"] for p in soon[:5]])
                message = f"📅 Истекает в течение недели: {names}"
                self._send_notification(message, soon, notify_callback)
                set_setting("last_notification_date", today)
    
    def _send_notification(self, message: str, products: list[dict], callback=None):
        """Send notification via available channel."""
        if callback:
            callback(message, products)
        else:
            self._send_system_notification(message)
    
    def _send_system_notification(self, message: str):
        """Send native system notification."""
        try:
            system = platform.system()
            
            if system == "Darwin":  # macOS
                import subprocess
                script = f'display notification "{message}" with title "Beauty Shelf"'
                subprocess.run(["osascript", "-e", script], capture_output=True)
                
            elif system == "Windows":
                from win10toast import ToastNotifier
                toaster = ToastNotifier()
                toaster.show_toast("Beauty Shelf", message, duration=5)
                
            elif system == "Linux":
                import subprocess
                subprocess.run([
                    "notify-send", 
                    "Beauty Shelf", 
                    message,
                    "-i", "dialog-information"
                ], capture_output=True)
            
            # For mobile (Flet), we rely on the app being open
            # Real push notifications require FCM integration
            
        except Exception as e:
            print(f"Failed to send notification: {e}")


# Singleton instance
_notification_service: Optional[NotificationService] = None

def get_notification_service() -> NotificationService:
    """Get or create notification service singleton."""
    global _notification_service
    if _notification_service is None:
        _notification_service = NotificationService()
    return _notification_service
