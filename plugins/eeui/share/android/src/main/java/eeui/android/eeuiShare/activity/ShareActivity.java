package eeui.android.eeuiShare.activity;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.Log;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.ActionBar;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.kaopiz.kprogresshud.KProgressHUD;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import app.eeui.framework.ui.eeui;
import eeui.android.eeuiShare.R;
import eeui.android.eeuiShare.adapter.FolderSelectAdapter;
import eeui.android.eeuiShare.adapter.ChatAdapter;
import eeui.android.eeuiShare.entity.User;
import eeui.android.eeuiShare.utils.StringSplitUtils;
import eeui.android.eeuiShare.utils.UriUtils;
import io.reactivex.rxjava3.android.schedulers.AndroidSchedulers;
import rxhttp.wrapper.param.RxHttp;

public class ShareActivity extends AppCompatActivity  {

    private static final String TAG = ShareActivity.class.getSimpleName();
    private RecyclerView recyclerView;
    private ChatAdapter chatAdapter;
    private LinearLayoutManager linearLayoutManager;

    private TextView tvSend;
    private TextView back;
    private List<User> sendUserChatList = new ArrayList<>();
    private eeui eeuiUtils;

    private List<User> showList = new ArrayList<>();
    private List<User> mainList = new ArrayList<>();

    //选中的目录
    private RecyclerView recyclerSelect;
    private LinearLayoutManager linearLayoutManagerSelect;
    private FolderSelectAdapter folderSelectAdapter;
    //选中的目录列表数据
    private List<User> folderSelectList = new ArrayList<>();

    private boolean isUploadDir = false;//是否上传到文件目录
    private List<String> filePathList = new ArrayList<>();

    private String urlUser = "";
    private int completeSign = 0;
    private String token = "";
    private Handler progressHandler ;
    private int uploadProgressTotal = 0;
    private LinearLayout refreshLayout;
    interface delayComplete {
        void complete();
    }
    private KProgressHUD kProgressHUD ;

    @SuppressLint("MissingInflatedId")
    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        ActionBar actionBar = getSupportActionBar();
        actionBar.hide();
        super.onCreate(savedInstanceState);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            getWindow().setStatusBarColor(Color.parseColor("#ffffff"));
            getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR);
        }
        setContentView(R.layout.activity_share);
        back = findViewById(R.id.back);
        back.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                finish();
            }
        });
        refreshLayout = findViewById(R.id.refreshLayout);
        refreshLayout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                getMainList();
            }
        });
        tvSend = findViewById(R.id.tv_send);

        tvSend.setTextColor(Color.parseColor("#33000000"));
        tvSend.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                upload();
            }
        });
        tvSend.setClickable(false);
        recyclerView = findViewById(R.id.recycler_view);
        recyclerSelect = findViewById(R.id.recyclerSelect);

        if (!init()) {
            return;
        }
        initShowList();
        initShowSelectList();
        getMainList();

        progressHandler = new Handler(Looper.getMainLooper()){
            @Override
            public void handleMessage(@NonNull Message msg) {
                super.handleMessage(msg);
                switch (msg.what){
                    case 1:
                        //计算总进度
                        uploadProgressTotal = 0;
                        for (int i=0;i<progressList.size();i++){
                            uploadProgressTotal += progressList.get(i) / progressList.size();
                        }
                        kProgressHUD.setProgress(uploadProgressTotal);
                        kProgressHUD.setLabel(getResources().getString(R.string.sendingTitle)+uploadProgressTotal+"%");
                        break;
                    default:
                        break;
                }
            }
        };
    }
    /**
     * 上传
     */
    private List<Integer> progressList = new ArrayList<>();
    public void upload(){
        kProgressHUD = KProgressHUD.create(this)
         .setStyle(KProgressHUD.Style.ANNULAR_DETERMINATE)
         .setMaxProgress(100)
         .setAutoDismiss(false)
         .show();

        completeSign = 0;
        progressList = new ArrayList<>();
        List<String> idList = new ArrayList<>();
        if (!isUploadDir && sendUserChatList.size()>0){
            String url ="";
            for (int i=0;i<sendUserChatList.size();i++){
                User tempUser = sendUserChatList.get(i);
                String idString = String.valueOf(tempUser.getExtend().getDialog_ids());
                idList.add(idString);
                url = tempUser.getUrl();
            }
            String idsString = StringSplitUtils.getStrings(idList);

            Log.i(TAG,"idsString="+idsString);
            for (int i = 0; i < filePathList.size(); i++) {
                progressList.add(0);
                String filePath = filePathList.get(i);
                upLoadFile(i, false,url,token,idsString,filePath);
            }

        }
        if (isUploadDir && folderSelectList.size()>1){
            User selectFolder = folderSelectList.get(folderSelectList.size()-1);
            //分享到文件夹的url拼接
            idList.add(String.valueOf(selectFolder.getExtend().getUpload_file_id()));
            String idsString = StringSplitUtils.getStrings(idList);
            for (int i = 0; i < filePathList.size(); i++) {
                progressList.add(0);
                String filePath = filePathList.get(i);
                String url = selectFolder.getUrl();
                upLoadFile(i, true,url,token,idsString,filePath);
            }
        }
    }
    public boolean init(){
        eeuiUtils = new eeui();

        //获取url连接
        Object objectUrlUser = eeuiUtils.getCaches(this,"chatList",new Object());
        Log.i(TAG, JSON.toJSONString(objectUrlUser));
        urlUser = JSON.toJSONString(objectUrlUser).replace("\"", "");//去除双眼号
        if (urlUser.length()<5){
            customToast(getResources().getString(R.string.unLoginTitle),true);
            return false;
        }
        Log.i(TAG,"urlUser="+urlUser);
        //截取_之后字符串
        if (!urlUser.equals("")){
            int index = urlUser.indexOf("=");
            String afterUrl = urlUser.substring(index + 1);
            token = afterUrl;
            Log.i(TAG,"token="+token);
        }

        Intent intent = getIntent();
        filePathList = new ArrayList<>();
        filePathList = getFilePathFromIntent(this,intent);
        if (filePathList.size()==0){
            customToast(getResources().getString(R.string.emptyShareTitle),true);
        }

        return true;
    }

    /**
     * 获取文件路径
     * @param context
     * @param intent
     * @return List<String>
     */
    private List<String> getFilePathFromIntent(Context context, Intent intent){
        String action = intent.getAction();
        String type = intent.getType();
        ArrayList<Uri> uriList = new ArrayList<>();
        ArrayList<String> pathList = new ArrayList<>();
        if (Intent.ACTION_SEND.equals(action) && type != null) {
            uriList.add(intent.getParcelableExtra(Intent.EXTRA_STREAM));
            String path = UriUtils.getRealPathFromURI(context,uriList.get(0));
            Log.i(TAG,"path="+path);
            pathList.add(path);

        } else if (Intent.ACTION_SEND_MULTIPLE.equals(action) && type != null) {
            uriList = intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM);
            if (uriList != null) {
                for (int i=0;i<uriList.size();i++){
                    String path = UriUtils.getRealPathFromURI(context,uriList.get(i));
                    Log.i(TAG,"path="+path);
                    pathList.add(path);
                }
            }
        }
        return pathList;
    }
    public void initShowList(){
        linearLayoutManager = new LinearLayoutManager(ShareActivity.this);
        recyclerView.setLayoutManager(linearLayoutManager);
        chatAdapter = new ChatAdapter(ShareActivity.this, showList);
        recyclerView.setAdapter(chatAdapter);
        chatAdapter.setOnItemListener(new ChatAdapter.OnItemListener() {
            @Override
            public void onClick(View view, int position, boolean isDir) {
                User user = showList.get(position);
                if (isDir){
                    if (isUploadDir == false) {
                        User all = new User();
                        all.setName(getResources().getString(R.string.allTitle));
                        folderSelectList.clear();
                        folderSelectList.add(all);
                    }
                    isUploadDir = true;
                    recyclerSelect.setVisibility(View.VISIBLE);
                    showList.clear();
                    String childrenUrl = user.getUrl()+"&"+"token="+token;
                    getSubList(childrenUrl);

                    folderSelectList.add(user);
                    folderSelectAdapter.setData(folderSelectList);
                }else {
                    isUploadDir = false;
                    if (user.isSelect()){
                        sendUserChatList.add(user);
                    }else {
                        sendUserChatList.remove(user);
                    }
                }
                changeSendBtnStatus();
            }
        });
    }

    private void initShowSelectList(){
        linearLayoutManagerSelect = new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL,false);
        recyclerSelect.setLayoutManager(linearLayoutManagerSelect);
        folderSelectAdapter = new FolderSelectAdapter(this,folderSelectList);
        recyclerSelect.setAdapter(folderSelectAdapter);
        folderSelectAdapter.setOnItemListener(new FolderSelectAdapter.OnItemListener() {
            @Override
            public void onClick(View view, int position) {
                //根据点击的item刷新选中列表数据
                List<User> list = new ArrayList<>();
                if (position == folderSelectList.size()-1) {
                    return;
                }
                for (int i = 0; i < position+1; i++) {
                    list.add(folderSelectList.get(i));
                }
                folderSelectList = list;
                folderSelectAdapter.setData(folderSelectList);
                if (list.size() <= 1 ){
                    isUploadDir = false;
                    recyclerSelect.setVisibility(View.GONE);
                    showList.clear();
//                    analyzeData();
//                    getMainList();
                    showList.addAll(mainList);
                    chatAdapter.setData(showList);
                    chatAdapter.notifyDataSetChanged();

                }else {
                    isUploadDir = true;
                    User last = folderSelectList.get(folderSelectList.size()-1);
                    showList.clear();
                    String childrenUrl = last.getUrl()+"&"+"token="+token;
                    getSubList(childrenUrl);
                }
                changeSendBtnStatus();
            }
        });
    }

    private void changeSendBtnStatus(){
        if (sendUserChatList.size()>0 || folderSelectList.size()>1){
            tvSend.setTextColor(Color.parseColor("#4169E1"));
            tvSend.setClickable(true);
            if (!isUploadDir && sendUserChatList.size()>0){
                tvSend.setText(getResources().getString(R.string.sendTitle)+"("+sendUserChatList.size()+")");
            }else if (isUploadDir && folderSelectList.size()>1){
                tvSend.setText(getResources().getString(R.string.sendTitle)+"("+1+")");
            }
        }else {
            tvSend.setTextColor(Color.parseColor("#33000000"));
            tvSend.setClickable(false);
            tvSend.setText(getResources().getString(R.string.sendTitle));
        }
    }
    //请求用户列表
    private void analyzeData() {
        chatAdapter.setData(showList);
    }

    @SuppressLint("CheckResult")
    private void getMainList(){
        kProgressHUD = KProgressHUD.create(this)
                .setStyle(KProgressHUD.Style.SPIN_INDETERMINATE)
                .setCancellable(true)
                .show();

        RxHttp.get(urlUser)
                .toObservableString()
                .observeOn(AndroidSchedulers.mainThread()) //指定在主线程回调
                .subscribe(s -> {
                    kProgressHUD.dismiss();
                    Log.i(TAG,"success="+s);
                    JSONObject jsonObject = JSON.parseObject(s);
                    Log.i(TAG,"success="+jsonObject.getIntValue("ret"));
                    if (jsonObject.getIntValue("ret") == 1) {

                        mainList = jsonObject.getJSONArray("data").toJavaList(User.class);

                        showList.addAll(mainList);
                        analyzeData();
                        refreshLayout.setVisibility(View.GONE);
                    }else {
                        String msg = jsonObject.getString("msg");
                        customToast(msg,false);
                        refreshLayout.setVisibility(View.VISIBLE);
                    }
                },throwable -> {
                    kProgressHUD.dismiss();
                    customToast(getResources().getString(R.string.netWorkErrorTitle),false);
                    Log.i(TAG,"throwable="+throwable);
                    refreshLayout.setVisibility(View.VISIBLE);
                });
    }
    @SuppressLint("CheckResult")
    private void getSubList(String url){
        kProgressHUD = KProgressHUD.create(this)
                .setStyle(KProgressHUD.Style.SPIN_INDETERMINATE)
                .setCancellable(true)
                .show();

        RxHttp.get(url)
                .toObservableString()
                .observeOn(AndroidSchedulers.mainThread()) //指定在主线程回调
                .subscribe(s -> {
                    kProgressHUD.dismiss();
                    Log.i(TAG,"success="+s);
                    JSONObject jsonObject = JSON.parseObject(s);
                    Log.i(TAG,"success="+jsonObject.getIntValue("ret"));
                    if (jsonObject.getIntValue("ret") == 1) {
                        showList = jsonObject.getJSONArray("data").toJavaList(User.class);
                        analyzeData();
                        refreshLayout.setVisibility(View.GONE);
                    }else {
                        String msg = jsonObject.getString("msg");
                        customToast(msg,false);
                        refreshLayout.setVisibility(View.VISIBLE);
                    }
                },throwable -> {
                    kProgressHUD.dismiss();
                    customToast(getResources().getString(R.string.netWorkErrorTitle),false);
                    Log.i(TAG,"throwable="+throwable);
                    refreshLayout.setVisibility(View.VISIBLE);
                });
    }
    //上传文件
    @SuppressLint("CheckResult")
    private void upLoadFile(int index, boolean isUploadDir, String url, String token, String idsString, String filePath){
        completeSign ++;
        RxHttp.postForm(url)
                .add("token",token)
                .add(isUploadDir?"upload_file_id":"dialog_ids",idsString)
                .addFile("files",new File(filePath))
                .toObservableString()
                .onMainProgress(progress -> {
                    progressList.set(index, progress.getProgress());
                    Message message = new Message();
                    message.what = 1;
                    progressHandler.sendMessage(message);
                    Log.i(TAG,"getProgress="+progress.getProgress());
                })
                .subscribe(s -> {
                    completeSign --;
                    Log.i(TAG,"throwable="+s);
                    JSONObject jsonObject = JSON.parseObject(s);
                    Log.i(TAG,"success="+jsonObject.getIntValue("ret"));
                    if (completeSign == 0) {
                        uploadComplete();
                    }
                },throwable -> {
                    completeSign --;
                    if (completeSign == 0) {
                        uploadComplete();
                    }
                    Log.i(TAG,"throwable="+throwable);
                });
    }

    private void uploadComplete() {
        int success = 0;
        int fail = 0;
        String msg = "";

        for (int i = 0; i < progressList.size(); i++) {
            int progress = progressList.get(i);
            if (progress == 100) {
                success ++;
            }else {
                fail ++;
            }
        }

        if (success == 0) {
            msg = getResources().getString(R.string.sendFailTitle);
        } else if (fail == 0) {
            msg = getResources().getString(R.string.sendSuccessTitle);
        }else {
            msg = success +getResources().getString(R.string.successTotal) +fail+getResources().getString(R.string.failTotal);
        }
        kProgressHUD.dismiss();
        customToast(msg,true);
    }
    private void customToast(String msg,final boolean finish){
        TextView textView = new TextView(this);
        textView.setText(msg);
        textView.setTextColor(Color.parseColor("#FFFFFF"));
        textView.setTextSize(16);
        kProgressHUD = KProgressHUD.create(this)
                .setCustomView(textView)
                .show();
        scheduleDismiss(new delayComplete() {
            @Override
            public void complete() {
                if (finish) {
                    finish();
                }
            }
        });
    }
    private void scheduleDismiss(delayComplete block) {

        Handler handler = new Handler();
        handler.postDelayed(new Runnable() {
            @Override
            public void run() {
                kProgressHUD.dismiss();
                if (block != null) {
                    block.complete();
                }
            }
        }, 1500);
    }
}
