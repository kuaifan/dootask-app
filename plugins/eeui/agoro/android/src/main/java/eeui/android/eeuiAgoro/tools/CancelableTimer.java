package eeui.android.eeuiAgoro.tools;
import android.os.Handler;
import android.os.Looper;

public class CancelableTimer {

    private final Handler handler = new Handler(Looper.getMainLooper());
    private final Runnable task;
    private boolean isCanceled = false;

    public CancelableTimer(final Runnable task) {
        this.task = new Runnable() {
            @Override
            public void run() {
                if (!isCanceled) {
                    task.run();
                }
            }
        };
    }

    public void start(long delayMillis) {
        handler.postDelayed(task, delayMillis);
    }

    public void cancel() {
        isCanceled = true;
        handler.removeCallbacks(task);
    }

}

