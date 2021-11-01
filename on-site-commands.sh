# Check role for each pod of the application

kubectl get pods|grep app-jade|awk '{print $1}'|while read p ; do 
    module=`kubectl describe pod $p|grep jade-app-module|awk '{print $2}' FS="="`;
    node=`kubectl describe pod $p|grep jade-node|awk '{print $2}' FS="="`;
    echo "${node}: ${module} -- ${p}";
done
