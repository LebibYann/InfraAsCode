import {
  Injectable,
  NotFoundException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, IsNull } from 'typeorm';
import { Task } from '../entities/task.entity';
import { CreateTaskDto } from '../dto/create-task.dto';
import { UpdateTaskDto } from '../dto/update-task.dto';
import { DeleteTaskDto } from '../dto/delete-task.dto';
import { GoneException } from '../common/exceptions/gone.exception';

@Injectable()
export class TasksService {
  private readonly logger = new Logger(TasksService.name);

  constructor(
    @InjectRepository(Task)
    private tasksRepository: Repository<Task>,
  ) {}

  async create(
    createTaskDto: CreateTaskDto,
    userId: string,
    correlationId: string,
  ): Promise<Task> {
    this.logger.log(
      `Creating task for user ${userId} - correlation_id: ${correlationId}`,
    );

    const task = this.tasksRepository.create({
      ...createTaskDto,
      userId,
      request_timestamp: new Date(createTaskDto.request_timestamp),
      last_request_timestamp: new Date(createTaskDto.request_timestamp),
    });

    return await this.tasksRepository.save(task);
  }

  async findAll(userId: string, correlationId: string): Promise<Task[]> {
    this.logger.log(
      `Fetching all tasks for user ${userId} - correlation_id: ${correlationId}`,
    );
    return await this.tasksRepository.find({
      where: { userId, deletedAt: IsNull() },
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(
    id: string,
    userId: string,
    correlationId: string,
  ): Promise<Task> {
    this.logger.log(
      `Fetching task ${id} for user ${userId} - correlation_id: ${correlationId}`,
    );

    const task = await this.tasksRepository.findOne({
      where: { id, userId },
    });

    if (!task) {
      throw new NotFoundException(`Task with ID ${id} not found`);
    }

    // Check if task was soft deleted
    if (task.deletedAt) {
      throw new GoneException(`Task with ID ${id} is no longer available`);
    }

    return task;
  }

  async update(
    id: string,
    updateTaskDto: UpdateTaskDto,
    userId: string,
    correlationId: string,
  ): Promise<Task> {
    this.logger.log(
      `Updating task ${id} for user ${userId} - correlation_id: ${correlationId}`,
    );

    const task = await this.findOne(id, userId, correlationId);
    const requestTimestamp = new Date(updateTaskDto.request_timestamp);

    // Check for out-of-order requests using request_timestamp
    if (
      task.last_request_timestamp &&
      requestTimestamp <= task.last_request_timestamp
    ) {
      this.logger.warn(
        `Conflict: Request timestamp ${requestTimestamp} is older than last request timestamp ${task.last_request_timestamp} - correlation_id: ${correlationId}`,
      );
      throw new ConflictException(
        'Request timestamp is older than the last processed request',
      );
    }

    // Update task fields
    if (updateTaskDto.title !== undefined) task.title = updateTaskDto.title;
    if (updateTaskDto.content !== undefined)
      task.content = updateTaskDto.content;
    if (updateTaskDto.due_date !== undefined)
      task.due_date = new Date(updateTaskDto.due_date);
    if (updateTaskDto.done !== undefined) task.done = updateTaskDto.done;

    task.last_request_timestamp = requestTimestamp;

    return await this.tasksRepository.save(task);
  }

  async remove(
    id: string,
    deleteTaskDto: DeleteTaskDto,
    userId: string,
    correlationId: string,
  ): Promise<void> {
    this.logger.log(
      `Deleting task ${id} for user ${userId} - correlation_id: ${correlationId}`,
    );

    const task = await this.findOne(id, userId, correlationId);
    const requestTimestamp = new Date(deleteTaskDto.request_timestamp);

    // Check for out-of-order requests using request_timestamp
    if (
      task.last_request_timestamp &&
      requestTimestamp <= task.last_request_timestamp
    ) {
      this.logger.warn(
        `Conflict: Request timestamp ${requestTimestamp} is older than last request timestamp ${task.last_request_timestamp} - correlation_id: ${correlationId}`,
      );
      throw new ConflictException(
        'Request timestamp is older than the last processed request',
      );
    }

    // Soft delete: mark as deleted instead of removing from database
    task.deletedAt = new Date();
    task.last_request_timestamp = requestTimestamp;
    await this.tasksRepository.save(task);
  }
}
