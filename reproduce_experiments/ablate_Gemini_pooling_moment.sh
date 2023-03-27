export CUDA_VISIBLE_DEVICES=2  # change as appropriate

num_thread=5
torch_thread=1
echo "...evaluating Gemini embeddings for BioGRID with varied standard moment for pooling"

for org in yeast mouse human_match
do
    if [ $org = yeast ]
    then
        ndim=200
    else
        ndim=400
    fi
    
    echo Running $org
    
    for moment in 1 2 3 4  # put 4 back in this when we're done
    do
        echo "Testing pooling for ${moment} standard moment"
        OPENBLAS_NUM_THREADS=5 python gemini/main_gemini_cluster.py --embed_type Qsm${moment} --axis 1 --level network --cluster_method ap --separate 35 --run_mashup 0 --num_thread $num_thread --torch_thread $torch_thread --method gemini --net GeneMANIA_ex --ndim $ndim --org $org
        OPENBLAS_NUM_THREADS=1 python gemini/main_gemini.py --num_thread $num_thread --torch_thread $torch_thread --method gemini --org $org --net GeneMANIA_ex --ndim 800 --embed_type Qsm${moment} --axis 1 --level network --cluster_method ap --separate 35 --weight 1 --ori_weight 0.5 --mixup 1 --mixup2 1.0 --gamma 0.5
        python gemini/main_classifier.py --ndim $ndim --embed_name gemini_${org}_GeneMANIA_ex_800_Qsm${moment}1_separate35_ap_weight1_0.5_network_mixup1_1.0_gamma0.5 --org $org --net GeneMANIA_ex --experiment_name gemini_${org}_GeneMANIA_ex_800_Qsm${moment}1_separate35_ap_weight1_0.5_network_mixup1_1.0_gamma0.5
    done
done

echo "...moving the results"
for org in yeast # mouse human_match
do
    if [ $org = yeast ]
    then
        ndim=200
    else
        ndim=400
    fi
    
    if [ $org = human_match ] 
    then
        short_org=human
    else
        short_org=$org
    fi
    
    for moment in 1 2 3 4
    do
        cp data/results/gemini_${org}_GeneMANIA_ex_800_Qsm${moment}1_separate35_ap_weight1_0.5_network_mixup1_1.0_gamma0.5_${ndim}_None_result.txt results/BioGrid/GEMINI/moment_${moment}_${short_org}.txt
    done
done

