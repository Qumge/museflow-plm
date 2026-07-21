module ApplicationHelper
  def simple_time datetime
    datetime.strftime('%Y-%m-%d')if datetime.present?
  end

  def simple_time_mini datetime
    datetime.strftime('%Y-%m-%d %H:%M:%S')if datetime.present?
  end


  def get_title params
    title_config[params[:controller].to_sym].present? ? title_config[params[:controller].to_sym][params[:action].to_sym] : ''
  end

  def title_config
    {

        products: {
            index: t('titles.products.index'),
            new: t('titles.products.new'),
            create: t('titles.products.create'),
            edit: t('titles.products.edit'),
            update: t('titles.products.update'),
            show: t('titles.products.show')
        },
        instances: {
            index: t('titles.instances.index'),
            new: t('titles.instances.new'),
            create: t('titles.instances.create'),
            edit: t('titles.instances.edit'),
            update: t('titles.instances.update'),
            show: t('titles.instances.show')
        },
        technologies: {
            index: t('titles.technologies.index'),
            new: t('titles.technologies.new'),
            create: t('titles.technologies.create'),
            edit: t('titles.technologies.edit'),
            update: t('titles.technologies.update'),
            show: t('titles.technologies.show')
        },
        home: {
            index: t('titles.home.index'),
            files_search: t('titles.home.files_search')
        },
        matters: {
            index: t('titles.matters.index'),
            show: t('titles.matters.show')
        }

    }
  end

  # 只替换当前页面 query string 里的 locale，保留路径和其余参数——
  # 导航栏语言切换入口用它拼出「留在当前页、换一种语言」的链接。
  def locale_switch_path(locale)
    query = request.query_parameters.merge('locale' => locale.to_s)
    "#{request.path}?#{query.to_query}"
  end

  def active_class params, controller, action=nil
    if action.present?
      params[:controller] == controller && params[:action] == action ? 'active' : ''
    else
      params[:controller] == controller ? 'active' : ''
    end
  end

  def show_file_name default_name, file
    file.file_name.size > 10 ? "#{default_name}_#{file.file_name[0..10]}" : file.file_name
  end

  # Wraps a ProductLog/InstanceLog/TechnologyLog/Matter's #get_status text
  # in a coloured badge (P5 Task 8, area 5). Colour is reserved for
  # approval status in this UI, so only the two terminal outcomes get a
  # hue: the underlying `status` column value 'active' (LogWorkflow's
  # "Released" / Matter's "Completed") is green, 'failed' ("Rejected",
  # LogWorkflow only) is red — every other status (wait/apply/develop/flow,
  # circulation/countersign) renders in the same neutral grey. The variant
  # is chosen from the raw `status` value, not the translated label, so it
  # doesn't depend on which locale is active.
  def status_badge(record)
    return unless record.respond_to?(:status) && record.status.present?

    variant = case record.status.to_s
              when 'active' then 'status-released'
              when 'failed' then 'status-rejected'
              else 'status-neutral'
              end
    content_tag(:span, record.get_status, class: "status-badge #{variant}")
  end

  def associated_models
    Product.all + Instance.all + Technology.all + Matter.all
  end

  def model_url model
    send "#{model.model_type.downcase}_path", model.model_id
  end

  # Server-side tree row builder: walks the records here and returns the
  # render order directly, as a flat array of { record:, depth: } — depth 0
  # is a top-level row, and every row is immediately followed by its
  # descendants (pre-order depth-first). app/views/shared/_list.html.erb
  # (Task 6) renders this straight into a <table>, which is what finally
  # makes the tree assertable by an HTTP test — the table used to be built
  # from a JSON blob in the browser by bootstrap-treetable.js, invisible to
  # any HTTP-level test.
  #
  # Used by the products and instances index pages: Product -> its
  # instances -> (recursively) their ancestry children is a real hierarchy
  # (a BOM tree), so recursion is correct there.
  #
  # `tree_rows` itself has no per-model branching — the one place that
  # knows how each business line nests is `tree_children` below.
  def tree_rows(records, depth: 0)
    records.flat_map do |record|
      [{ record: record, depth: depth }] + tree_rows(tree_children(record), depth: depth + 1)
    end
  end

  # 工艺文件的"子行"和产品的"子行"不是一回事：
  #   产品 → 零件 → 子零件，是层级（BOM 树），递归展开是对的（走 tree_rows）
  #   工艺文件 → 用到它的零件与产品，是【平铺的引用关系】，递归会让同一个
  #     零件既作为工艺的直接子行、又作为产品的子行出现两次
  # 所以这里显式只铺一层，用于 technologies 的 index 页面。
  def technology_tree_rows(technologies)
    technologies.flat_map do |technology|
      [{ record: technology, depth: 0 }] +
        (technology.instances.to_a + technology.products.to_a)
          .map { |used_by| { record: used_by, depth: 1 } }
    end
  end

  # 只有一页时不渲染分页条。
  #
  # 无条件渲染 card-footer 会在表格下面留一条空白带——有上边框、有内边距、
  # 里面什么都没有，看起来像表格后面又多出一个空盒子。这个模式原本在 5 处
  # 各写了一遍（home/index、home/files_search、shared/_list、notices 的收发件箱），
  # 收口到这里，避免下次再漏掉某一处。
  def paginated_footer(collection, **paginate_options)
    return unless collection.respond_to?(:total_pages) && collection.total_pages > 1

    content_tag :div, class: 'card-footer d-flex justify-content-end' do
      paginate(collection, theme: 'bootstrap-5', **paginate_options)
    end
  end

  private

  # Polymorphic "what nests under this row" lookup for tree_rows.
  # Product -> its instances; Instance -> its ancestry children (so a
  # part's own sub-parts recurse to depth+1, depth+2, ...); anything
  # else (Technology, Matter, ...) has no children in this tree.
  def tree_children(record)
    case record
    when Product  then record.instances
    when Instance then record.children
    else []
    end
  end
end
