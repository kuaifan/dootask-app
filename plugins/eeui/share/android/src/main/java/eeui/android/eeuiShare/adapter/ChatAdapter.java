package eeui.android.eeuiShare.adapter;

import android.annotation.SuppressLint;
import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import java.util.List;

import app.eeui.framework.extend.integration.glide.Glide;
import app.eeui.framework.extend.integration.glide.load.resource.bitmap.CircleCrop;
import app.eeui.framework.extend.integration.glide.request.RequestOptions;
import eeui.android.eeuiShare.R;
import eeui.android.eeuiShare.entity.User;

public class ChatAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {

    private Context context;
    private List<User> mList;
    public ChatAdapter(Context context, List<User> list){
        this.context = context;
        mList = list;
    }

    public void setData(List<User> list){
        mList = list;
        notifyDataSetChanged();
    }
    @NonNull
    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.layout_item_user,parent,false);
        ChatViewHolder holder = new ChatViewHolder(view);
        return holder;
    }

    @Override
    public void onBindViewHolder(@NonNull RecyclerView.ViewHolder holder, @SuppressLint("RecyclerView") int position) {
        ChatViewHolder userViewHolder = (ChatViewHolder)holder;
        User user = mList.get(position);
        Glide.with(context).load(user.getIcon()).apply(RequestOptions.bitmapTransform(new CircleCrop())).into(userViewHolder.avatar);
        userViewHolder.name.setText(user.getName());
        if (user.getType().equals("item")){
            if (user.isSelect() == true){
                Glide.with(context).load(R.drawable.radio_button_selected).apply(RequestOptions.bitmapTransform(new CircleCrop())).into(userViewHolder.imgSelect);
            }else {
                Glide.with(context).load(R.drawable.radio_button_default).apply(RequestOptions.bitmapTransform(new CircleCrop())).into(userViewHolder.imgSelect);
            }
        }else if (user.getType().equals("children")){
            Glide.with(context).load(R.drawable.folder).apply(RequestOptions.bitmapTransform(new CircleCrop())).into(userViewHolder.avatar);
            Glide.with(context).load(R.drawable.arrow_black_right).into(userViewHolder.imgSelect);
            userViewHolder.name.setText(user.getName());
        }

        holder.itemView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                User user = mList.get(position);
                if (user.getType().equals("children")){
                    if (onItemListener!=null){
                        onItemListener.onClick(holder.itemView, position,true);
                        return;
                    }
                } else if (user.getType().equals("item")){
                    if (user.isSelect()){
                        user.setSelect(false);
                    }else {
                        user.setSelect(true);
                    }
                }
                if (onItemListener!=null){
                    onItemListener.onClick(holder.itemView, position,false);
                }
                notifyDataSetChanged();
            }
        });
    }

    @Override
    public int getItemCount() {
        return mList.size();
    }
    public class ChatViewHolder extends RecyclerView.ViewHolder {
        public LinearLayout layoutItem;
        public ImageView avatar;
        public TextView name;
        public ImageView imgSelect;
        public ChatViewHolder(@NonNull View itemView) {
            super(itemView);
            layoutItem = itemView.findViewById(R.id.layoutItem);
            avatar = itemView.findViewById(R.id.avatar);
            name = itemView.findViewById(R.id.name);
            imgSelect = itemView.findViewById(R.id.imgSelect);
        }
    }
    public void setOnItemListener(OnItemListener onItemListener) {
        this.onItemListener = onItemListener;
    }
    public interface OnItemListener {
        void onClick(View view, int position, boolean isDir);
    }
    private OnItemListener onItemListener;
}
