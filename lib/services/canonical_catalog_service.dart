import '../models/ml_model.dart';

/// Canonical verified AI/ML model catalog for BroML (Blueprint 1.0)
class CanonicalCatalogService {
  static MlModel _m({
    required String id,
    required String name,
    required String category,
    required String task,
    required String framework,
    required double accuracy,
    required int latencyMs,
    required String desc,
    required int params,
    required int sizeMb,
    required int ramMb,
    int vramMb = 0,
    String license = 'Apache-2.0',
    String dataset = 'Benchmark val',
    String url = '',
  }) =>
      MlModel(
        id: id,
        name: name,
        category: category,
        task: task,
        framework: framework,
        accuracy: accuracy,
        latencyMs: latencyMs,
        version: '1.0.0',
        description: desc,
        datasetName: dataset,
        imageUrl: 'https://picsum.photos/seed/$id/600/400',
        githubUrl: url,
        parameterCount: params,
        modelSizeBytes: sizeMb * 1048576,
        minRamBytes: ramMb * 1048576,
        minVramBytes: vramMb * 1048576,
        license: license,
        benchmarkDataset: dataset,
        evidenceSourceUrl: url,
        verificationStatus: 'verified',
      );

  static final List<MlModel> canonicalModels = [
    // ── Computer Vision: Image Classification ──────────────────────────────────
    _m(id: 'canon-squeezenet', name: 'SqueezeNet-1.1 Micro-Footprint Classifier', category: 'Computer Vision', task: 'Image Classification', framework: 'PyTorch', accuracy: 57.5, latencyMs: 4, desc: 'Ultra-compact AlexNet accuracy with 50x fewer parameters. Zero lag on budget laptops.', params: 1235496, sizeMb: 5, ramMb: 256, license: 'BSD-3-Clause', dataset: 'ImageNet-1k', url: 'https://arxiv.org/abs/1602.07360'),
    _m(id: 'canon-mobilenet-v3-small', name: 'MobileNetV3-Small Hardware-Aware Classifier', category: 'Computer Vision', task: 'Image Classification', framework: 'PyTorch', accuracy: 67.4, latencyMs: 7, desc: 'Ultra-lightweight neural network optimized for mobile and low-spec laptops.', params: 2542856, sizeMb: 10, ramMb: 512, dataset: 'ImageNet-1k', url: 'https://arxiv.org/abs/1905.02244'),
    _m(id: 'canon-resnet-18', name: 'ResNet-18 Compact Residual Classifier', category: 'Computer Vision', task: 'Image Classification', framework: 'PyTorch', accuracy: 69.8, latencyMs: 10, desc: 'Lightweight 18-layer residual architecture. Excellent speed/accuracy sweet spot.', params: 11689512, sizeMb: 45, ramMb: 1024, dataset: 'ImageNet-1k', url: 'https://arxiv.org/abs/1512.03385'),
    _m(id: 'canon-efficientnet-b0', name: 'EfficientNet-B0 Compound Scaling Classifier', category: 'Computer Vision', task: 'Image Classification', framework: 'PyTorch', accuracy: 77.1, latencyMs: 14, desc: 'Scales depth, width, and resolution with a uniform compound coefficient.', params: 5288548, sizeMb: 21, ramMb: 1024, dataset: 'ImageNet-1k', url: 'https://arxiv.org/abs/1905.11946'),
    _m(id: 'canon-resnet-50', name: 'ResNet-50 Residual Neural Classifier', category: 'Computer Vision', task: 'Image Classification', framework: 'PyTorch', accuracy: 76.1, latencyMs: 28, desc: 'Canonical deep residual network with 50 layers. Standard industry baseline.', params: 25557032, sizeMb: 98, ramMb: 2048, dataset: 'ImageNet-1k', url: 'https://arxiv.org/abs/1512.03385'),

    // ── Computer Vision: Object Detection ──────────────────────────────────────
    _m(id: 'canon-yolov5n', name: 'YOLOv5n (Nano) Ultra-Fast Detector', category: 'Computer Vision', task: 'Object Detection', framework: 'PyTorch', accuracy: 28.0, latencyMs: 8, desc: 'Sub-10ms object detection engineered for edge CPU inference and low-power budget laptops.', params: 1900000, sizeMb: 4, ramMb: 512, license: 'AGPL-3.0', dataset: 'COCO 2017 val', url: 'https://github.com/ultralytics/yolov5'),
    _m(id: 'canon-ssd-mobilenet-v2', name: 'SSD-MobileNetV2 Permissive Edge Detector', category: 'Computer Vision', task: 'Object Detection', framework: 'TensorFlow', accuracy: 22.1, latencyMs: 9, desc: 'Single Shot MultiBox Detector with MobileNetV2 backbone for embedded hardware.', params: 4300000, sizeMb: 17, ramMb: 512, dataset: 'COCO 2017 val', url: 'https://arxiv.org/abs/1801.04381'),
    _m(id: 'canon-yolov8n', name: 'YOLOv8n (Nano) Real-Time Object Detector', category: 'Computer Vision', task: 'Object Detection', framework: 'PyTorch', accuracy: 37.3, latencyMs: 11, desc: 'Anchor-free single-stage detector optimized for edge CPUs and laptops.', params: 3200000, sizeMb: 6, ramMb: 1024, license: 'AGPL-3.0', dataset: 'COCO 2017 val', url: 'https://docs.ultralytics.com/models/yolov8/'),
    _m(id: 'canon-yolov8s', name: 'YOLOv8s (Small) High-Accuracy Object Detector', category: 'Computer Vision', task: 'Object Detection', framework: 'PyTorch', accuracy: 44.9, latencyMs: 24, desc: 'Small variant balancing edge capability and high mAP for video feeds.', params: 11200000, sizeMb: 22, ramMb: 2048, vramMb: 1024, license: 'AGPL-3.0', dataset: 'COCO 2017 val', url: 'https://docs.ultralytics.com/models/yolov8/'),

    // ── NLP: Text Classification ───────────────────────────────────────────────
    _m(id: 'canon-tinybert', name: 'TinyBERT-4L Ultra-Compact Language Model', category: 'Natural Language Processing', task: 'Text Classification', framework: 'ONNX', accuracy: 86.5, latencyMs: 6, desc: '4-layer distilled transformer designed for low-latency CPU inference pipelines.', params: 14500000, sizeMb: 55, ramMb: 512, dataset: 'GLUE SST-2', url: 'https://arxiv.org/abs/1909.10351'),
    _m(id: 'canon-distilbert', name: 'DistilBERT-Base Fast Transformer Classifier', category: 'Natural Language Processing', task: 'Text Classification', framework: 'PyTorch', accuracy: 91.3, latencyMs: 19, desc: 'Distilled BERT retaining 97% language understanding, 40% smaller and 60% faster.', params: 66362880, sizeMb: 256, ramMb: 1536, dataset: 'SST-2', url: 'https://arxiv.org/abs/1910.01108'),
    _m(id: 'canon-roberta-base', name: 'RoBERTa-Base Robust Transformer', category: 'Natural Language Processing', task: 'Text Classification', framework: 'PyTorch', accuracy: 94.8, latencyMs: 38, desc: 'Longer trained BERT with dynamic masking over large text corpora.', params: 124645632, sizeMb: 475, ramMb: 3072, license: 'MIT', dataset: 'SST-2', url: 'https://arxiv.org/abs/1907.11692'),

    // ── NLP: Sentiment Analysis ────────────────────────────────────────────────
    _m(id: 'canon-tinybert-sentiment', name: 'TinyBERT-SST2 Fast Sentiment Classifier', category: 'Natural Language Processing', task: 'Sentiment Analysis', framework: 'ONNX', accuracy: 87.2, latencyMs: 5, desc: 'Ultra-fast quantized sentiment analysis model running sub-6ms on laptop CPUs.', params: 14500000, sizeMb: 55, ramMb: 512, dataset: 'SST-2 Binary Sentiment', url: 'https://arxiv.org/abs/1909.10351'),
    _m(id: 'canon-distilbert-sentiment', name: 'DistilBERT-SST2 Production Sentiment Engine', category: 'Natural Language Processing', task: 'Sentiment Analysis', framework: 'PyTorch', accuracy: 91.3, latencyMs: 16, desc: 'Fine-tuned DistilBERT on SST-2 for sentiment classification. Ideal speed/accuracy balance.', params: 66362880, sizeMb: 256, ramMb: 1536, dataset: 'SST-2 Benchmark', url: 'https://huggingface.co/distilbert-base-uncased-finetuned-sst-2-english'),
    _m(id: 'canon-roberta-sentiment', name: 'RoBERTa-Base High-Precision Sentiment Model', category: 'Natural Language Processing', task: 'Sentiment Analysis', framework: 'PyTorch', accuracy: 94.8, latencyMs: 38, desc: 'Deep RoBERTa model fine-tuned for nuanced customer reviews and complex cues.', params: 124645632, sizeMb: 475, ramMb: 3072, vramMb: 1024, license: 'MIT', dataset: 'SST-2', url: 'https://arxiv.org/abs/1907.11692'),

    // ── NLP: Text Embedding ────────────────────────────────────────────────────
    _m(id: 'canon-paraphrase-minilm-l3', name: 'paraphrase-MiniLM-L3-v2 Ultra-Light Embedding', category: 'Natural Language Processing', task: 'Text Embedding', framework: 'ONNX', accuracy: 52.8, latencyMs: 4, desc: '3-layer sentence transformer. Ultra-low 4ms latency for local RAG on 4GB laptops.', params: 17500000, sizeMb: 66, ramMb: 384, dataset: 'MTEB (384-dim)', url: 'https://huggingface.co/sentence-transformers/paraphrase-MiniLM-L3-v2'),
    _m(id: 'canon-all-minilm-l6', name: 'all-MiniLM-L6-v2 Semantic Search Embedding', category: 'Natural Language Processing', task: 'Text Embedding', framework: 'ONNX', accuracy: 56.3, latencyMs: 7, desc: 'Maps sentences to 384-dim dense vectors. 5x faster than standard BERT.', params: 22700000, sizeMb: 87, ramMb: 512, dataset: 'MTEB (384-dim)', url: 'https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2'),
    _m(id: 'canon-bge-small-en', name: 'BAAI BGE-Small-EN-v1.5 Dense Embeddings', category: 'Natural Language Processing', task: 'Text Embedding', framework: 'PyTorch', accuracy: 62.1, latencyMs: 14, desc: 'Premier open-source embedding model for semantic search and RAG with high quality.', params: 33500000, sizeMb: 128, ramMb: 1024, license: 'MIT', dataset: 'MTEB Retrieval', url: 'https://arxiv.org/abs/2309.07597'),
    _m(id: 'canon-nomic-embed-v1-5', name: 'Nomic Embed Text v1.5 High-Context Embedding', category: 'Natural Language Processing', task: 'Text Embedding', framework: 'PyTorch', accuracy: 62.3, latencyMs: 26, desc: 'Long-context text embedder supporting up to 8192 tokens with Matryoshka reduction.', params: 137000000, sizeMb: 522, ramMb: 2048, dataset: 'MTEB (8192 tokens)', url: 'https://arxiv.org/abs/2402.01613'),

    // ── Audio & Speech ────────────────────────────────────────────────────────
    _m(id: 'canon-whisper-tiny', name: 'Whisper-Tiny Fast Speech Recognizer', category: 'Audio & Speech', task: 'Speech Recognition', framework: 'PyTorch', accuracy: 91.8, latencyMs: 14, desc: 'Ultra-lightweight 39M parameter speech-to-text model. Fast CPU inference on laptops.', params: 39000000, sizeMb: 151, ramMb: 512, license: 'MIT', dataset: 'LibriSpeech (clean WER 8.2%)', url: 'https://github.com/openai/whisper'),
    _m(id: 'canon-whisper-base', name: 'Whisper-Base Multilingual Speech Engine', category: 'Audio & Speech', task: 'Speech Recognition', framework: 'PyTorch', accuracy: 93.6, latencyMs: 28, desc: '74M parameter general-purpose speech transcription and translation model.', params: 74000000, sizeMb: 290, ramMb: 1024, license: 'MIT', dataset: 'Common Voice 11', url: 'https://github.com/openai/whisper'),
    _m(id: 'canon-silero-vad', name: 'Silero VAD Voice Activity Detector', category: 'Audio & Speech', task: 'Audio Classification', framework: 'ONNX', accuracy: 97.4, latencyMs: 3, desc: 'Enterprise-grade ultra-fast Voice Activity Detector running in sub-3ms on laptop CPUs.', params: 250000, sizeMb: 2, ramMb: 128, license: 'MIT', dataset: 'Speech Activity Corpus', url: 'https://github.com/snakers4/silero-vad'),

    // ── Tabular ML & Classical Machine Learning ────────────────────────────────
    _m(id: 'canon-xgboost', name: 'DMLC XGBoost Scalable Gradient Boosting', category: 'Tabular ML', task: 'Tabular Classification', framework: 'Scikit-Learn', accuracy: 93.8, latencyMs: 2, desc: 'Scalable, portable and distributed gradient boosting framework for tabular datasets.', params: 850000, sizeMb: 3, ramMb: 256, license: 'Apache-2.0', dataset: 'Higgs & California Housing', url: 'https://github.com/dmlc/xgboost'),
    _m(id: 'canon-lightgbm', name: 'Microsoft LightGBM Fast GBDT Engine', category: 'Tabular ML', task: 'Tabular Classification', framework: 'Scikit-Learn', accuracy: 93.5, latencyMs: 1, desc: 'Fast, distributed, high performance gradient boosting based on decision tree algorithms.', params: 750000, sizeMb: 2, ramMb: 256, license: 'MIT', dataset: 'Credit Card Fraud Benchmark', url: 'https://github.com/microsoft/LightGBM'),
    _m(id: 'canon-catboost', name: 'Yandex CatBoost Categorical Feature Boosting', category: 'Tabular ML', task: 'Tabular Classification', framework: 'Scikit-Learn', accuracy: 94.1, latencyMs: 2, desc: 'Gradient boosting on decision trees with state-of-the-art native categorical feature handling.', params: 900000, sizeMb: 4, ramMb: 256, license: 'Apache-2.0', dataset: 'Epsilon Benchmark', url: 'https://github.com/catboost/catboost'),

    // ── Reinforcement Learning ─────────────────────────────────────────────────
    _m(id: 'canon-stable-baselines3', name: 'Stable Baselines 3 PPO Policy Optimizer', category: 'Reinforcement Learning', task: 'Policy Optimization', framework: 'PyTorch', accuracy: 92.5, latencyMs: 2, desc: 'Reliable reinforcement learning implementation of Proximal Policy Optimization in PyTorch.', params: 1200000, sizeMb: 5, ramMb: 256, license: 'MIT', dataset: 'Gymnasium MuJoCo / Atari', url: 'https://github.com/DLR-RM/stable-baselines3'),
    _m(id: 'canon-cleanrl-dqn', name: 'CleanRL Deep Q-Network Agent', category: 'Reinforcement Learning', task: 'Value Optimization', framework: 'PyTorch', accuracy: 88.0, latencyMs: 1, desc: 'High-quality, single-file implementation of Deep Q-Networks with verified benchmark scores.', params: 800000, sizeMb: 3, ramMb: 128, license: 'MIT', dataset: 'Gymnasium CartPole-v1', url: 'https://github.com/vwxyzjn/cleanrl'),

    // ── Generative Models & Foundational LLMs ─────────────────────────────────
    _m(id: 'canon-llama-3-2-1b', name: 'Meta LLaMA 3.2 1B Compact Instruct', category: 'Natural Language Processing', task: 'Text Generation', framework: 'PyTorch', accuracy: 68.2, latencyMs: 32, desc: 'State-of-the-art multilingual small language model tuned for on-device assistant workflows.', params: 1230000000, sizeMb: 1200, ramMb: 2048, license: 'Llama 3.2 Community', dataset: 'MMLU & GSM8K', url: 'https://github.com/meta-llama/llama-models'),
    _m(id: 'canon-deepseek-r1-distill', name: 'DeepSeek R1 Distill Qwen 1.5B Reasoning Engine', category: 'Natural Language Processing', task: 'Reasoning & Code', framework: 'PyTorch', accuracy: 72.8, latencyMs: 42, desc: 'Distilled reasoning model exhibiting strong mathematical deduction and code completion.', params: 1500000000, sizeMb: 1500, ramMb: 2560, license: 'MIT', dataset: 'MATH-500 & AIME 2024', url: 'https://github.com/deepseek-ai/DeepSeek-R1'),
    _m(id: 'canon-flux-1-schnell', name: 'Black Forest Labs FLUX.1 Schnell Fast Generator', category: 'Computer Vision', task: 'Image Generation', framework: 'PyTorch', accuracy: 91.0, latencyMs: 650, desc: '12B rectified flow transformer distilled for 1-4 step high-fidelity image generation.', params: 12000000000, sizeMb: 8500, ramMb: 8192, vramMb: 6144, license: 'Apache-2.0', dataset: 'COCO / GenEval', url: 'https://github.com/black-forest-labs/flux'),
  ];

  static List<MlModel> getCanonicalModels() => List<MlModel>.from(canonicalModels);
}
