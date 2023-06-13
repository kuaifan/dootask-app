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

import eeui.android.eeuiShare.R;
import eeui.android.eeuiShare.entity.User;

public class FolderSelectAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {

    private Context context;
    private List<User> mList;
    public FolderSelectAdapter(Context context, List<User> list){
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
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.layout_item_folder_select,parent,false);
        FolderDirectoryViewHolder holder = new FolderDirectoryViewHolder(view);
        return holder;
    }

    @Override
    public void onBindViewHolder(@NonNull RecyclerView.ViewHolder holder, @SuppressLint("RecyclerView") int position) {
        FolderDirectoryViewHolder folderViewHolder = (FolderDirectoryViewHolder)holder;
        User folderDirectory = mList.get(position);
        folderViewHolder.name.setText(folderDirectory.getName());
        if (position == mList.size() - 1) {
            folderViewHolder.right.setVisibility(View.GONE);
        }else {
            folderViewHolder.right.setVisibility(View.VISIBLE);
        }
        holder.itemView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (onItemListener!=null){
                    onItemListener.onClick(holder.itemView, position);
                }
            }
        });
    }

    @Override
    public int getItemCount() {
        return mList.size();
    }

    public class FolderDirectoryViewHolder extends RecyclerView.ViewHolder {
        public LinearLayout layoutItem;
        public TextView name;
        public ImageView right;
        public FolderDirectoryViewHolder(@NonNull View itemView) {
            super(itemView);
            layoutItem = itemView.findViewById(R.id.layoutItem);
            name = itemView.findViewById(R.id.name);
            right = itemView.findViewById(R.id.right);
        }
    }
    public void setOnItemListener(OnItemListener onItemListener) {
        this.onItemListener = onItemListener;
    }
    public interface OnItemListener {
        void onClick(View view, int position);
    }
    private OnItemListener onItemListener;
}
